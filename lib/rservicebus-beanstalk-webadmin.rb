require 'beanstalk-client'
require 'rservicebus2'
require 'json'
require 'sinatra'

class RServiceBusBeanstalkAdmin < Sinatra::Base

set :public_folder, File.expand_path('../../public', __FILE__)
set :bind, '0.0.0.0'

before do
  @host_string = ENV['BEANSTALK_HOST'] || 'localhost:11300'
  @beanstalk = Beanstalk::Pool.new([@host_string])
end

after do
  @beanstalk.close
end

def convert_rservicebus2_msg_to_hash(idx, body)
  if body.index('RServiceBus2::Message').nil?
    return Hash['idx', 'id', 'error_list', []]
  end

  msg_wrapper = YAML.load(body)

  hash = Hash['idx', idx,
              'msg_id', msg_wrapper.msg_id,
              'return_address', msg_wrapper.return_address,
              'body', body,
              'error_list', []]

  msg_wrapper.error_list.each do |e|
    h = Hash['occurredat', e.occurredat,
             'source_queue', e.source_queue,
             'error_msg', e.error_msg]
    hash['error_list'] << h
  end

  hash['name'] = body.match('ruby/object:([A-Za-z0-9_:]*?)[^A-Za-z0-9_:]',
                            '-- !ruby/object:RServiceBus2::Message'.length)[1]
  hash
end

def convert_rservicebus_msg_to_hash(idx, body)
  require 'rservicebus'
  msg_wrapper = YAML.load(body)

  hash = Hash['idx', idx,
              'msg_id', msg_wrapper.msgId,
              'return_address', msg_wrapper.returnAddress,
              'body', body,
              'error_list', []]

#  msg_wrapper.error_list.each do |e|
#    h = Hash['occurredat', e.occurredat,
#             'source_queue', e.source_queue,
#             'error_msg', e.error_msg]
#    hash['error_list'] << h
#  end

  hash['name'] = body.match('ruby/object:([A-Za-z0-9_:]*?)[^A-Za-z0-9_:]',
                            '-- !ruby/object:RServiceBus2::Message'.length)[1]
  hash
end

def convert_msg_to_hash(idx, body)
  return convert_rservicebus2_msg_to_hash(idx, body) unless body.index('RServiceBus2::Message').nil?
  return convert_rservicebus_msg_to_hash(idx, body) unless body.index('RServiceBus::Message').nil?

  Hash['idx', 'id', 'error_list', []]
end

get '/path' do
  puts File.expand_path('../../public', __FILE__)
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

    msg = convert_msg_to_hash(idx, job.body)
    body_list << msg
  end

  job_list.each(&:release)

  body_list.to_json
end
end

RServiceBusBeanstalkAdmin.run!
