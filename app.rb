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
              'return_address', msg_wrapper.return_address]

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

=begin
        case true
            when request_name == "tube" && path_list.count == 2 then




            when request_name == "tube" && path_list.count == 3 then

                beanstalk = self.getBeanstalkConnection
                tubeStats = beanstalk.stats_tube(path_list[2])
                beanstalk.close

                response.status = 200
                response.body = [tubeStats.to_json]

            when request_name == "tube" && path_list.count == 4 && path_list[3] == "list" && request.request_method == "DELETE" then
                beanstalk = self.getBeanstalkConnection
                stats = beanstalk.stats_tube(path_list[2])
                index = stats["current-jobs-ready"].to_i

                beanstalk.watch(path_list[2])
                bodyList = Array.new
                1.upto(index) do
                    job = beanstalk.reserve 1
                    job.delete
                end
                beanstalk.close
                response.status = 200

            when request_name == "tube" && path_list.count == 4 && path_list[3] == "list" then
                jobList = Array.new

                beanstalk = self.getBeanstalkConnection

                stats = beanstalk.stats_tube(path_list[2])
                index = stats["current-jobs-ready"].to_i

                beanstalk.watch(path_list[2])
                bodyList = Array.new
                1.upto(index) do |idx|
                    job = beanstalk.reserve 1
                    jobList << job

                    msg = convert_rservicebus2_msg_to_hash(idx, job.body)
                    bodyList << msg
                end


                jobList.each do |job|
                    job.release
                end
                beanstalk.close

                response.status = 200
                response.body = [bodyList.to_json]

            when request_name == "tube" && path_list.count == 4 && path_list[3].to_i != 0 && request.request_method == "DELETE" then
                jobList = Array.new
                index = path_list[3].to_i

                beanstalk = self.getBeanstalkConnection
                beanstalk.watch(path_list[2])
                job = nil
                1.upto(index) do
                    job = beanstalk.reserve 1
                    jobList << job
                end

                job.delete
                jobList.pop

                response.status = 200

                jobList.each do |job|
                    job.release
                end
                beanstalk.close

            when request_name == "tube" && path_list.count == 4 && path_list[3].to_i != 0 then
                jobList = Array.new
                index = path_list[3].to_i

                beanstalk = self.getBeanstalkConnection
                beanstalk.watch(path_list[2])
                body = ""
                1.upto(index) do
                    job = beanstalk.reserve 1
                    jobList << job
                    body = job.body
                end
            #                puts jobList.last.body
                response.status = 200
                response.body = [body.to_s]

                jobList.each do |job|
                    job.release
                end
                beanstalk.close

            else
                response.status = 404
        end

        response.finish
    end

end
=end
