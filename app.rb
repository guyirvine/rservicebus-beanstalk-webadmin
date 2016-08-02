require 'beanstalk-client'
require 'rservicebus2'
require 'json'
require 'sinatra'

before do
  @host_string = ENV['BEANSTALK_HOST'] || 'localhost:11300'
  @beanstalk = Beanstalk::Pool.new([@host_string])
end

after do
  @beanstalk.close
end

def convert_rservicebus2_msg_to_hash(idx, body)
  msg_wrapper = YAML.load(body)

  hash = Hash['idx', idx,
              'msg_id', msg_wrapper.msg_id,
              'return_address', msg_wrapper.return_address,
              'error_list', []]
  msg_wrapper.error_list.each do |e|
    h = Hash['occurredat', e.occurredat,
             'source_queue', e.source_queue,
             'error_msg', e.error_msg]
    hash['error_list'] << h
  end

#  e = msg_wrapper.last_error_msg
#  unless e.nil?
#    error = Hash['occurredAt', e.occurredAt,
#                 'sourceQueue', e.sourceQueue,
#                 'errorMsg', e.errorMsg]
#    hash['last_error'] = error
#  end

  hash['name'] = body.match('ruby/object:([A-Za-z0-9_:]*?)[^A-Za-z0-9_:]',
                            '-- !ruby/object:RServiceBus::Message'.length)[1]
  hash
end

get '/tube' do
  hash = @beanstalk.list_tubes
  hash[@host_string].to_json
end

get '/tube/:name' do
  @beanstalk.stats_tube(params['name']).to_json
end

get '/tube/:name/list' do
  job_list = []

  stats = @beanstalk.stats_tube(params['name'])
  job_count = stats['current-jobs-ready'].to_i

  @beanstalk.watch(params['name'])
  body_list = []
  1.upto(job_count) do |idx|
    job = @beanstalk.reserve 1
    job_list << job

    msg = convert_rservicebus2_msg_to_hash(idx, job.body)
    body_list << msg
  end

  job_list.each(&:release)

  body_list.to_json
end
