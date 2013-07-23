require "beanstalk-client"
require "rservicebus"
require "json"

#skey = request.cookies["session"]
#response.set_cookie("session", skey.to_s)
#response.set_cookie("llid", {:value => rkey.to_s, :path => "/", :expires => ( Date.today >> 3 ).to_time}) if !rkey.nil?
#response.status = 200
#response.set_cookie("session", skey.to_s)
#response.body = [Hash["s", skey.to_s, "l", rkey.to_s].to_json]

class Manager
    
    def initialize
        @beanstalkConnectionString = ENV["BEANSTALK_HOST"]
    end
    
    def getBeanstalkConnection
        host = @beanstalkConnectionString
        beanstalk = Beanstalk::Pool.new([host])
        
        return beanstalk
    end
    
    def convertRServiceBusMsgToHash( idx, body )
        msgWrapper = YAML::load(body)
        
        hash = Hash.new
        hash["idx"] = idx
        hash["msgId"] = msgWrapper.msgId
        hash["returnAddress"] = msgWrapper.returnAddress
        
        e = msgWrapper.getLastErrorMsg
        if !e.nil? then
            error = Hash["occurredAt", e.occurredAt, "sourceQueue", e.sourceQueue, "errorMsg", e.errorMsg]
            hash["lastError"] = error
        end

        hash["name"] = body.match( "ruby/object:([A-Za-z0-9_:]*?)[^A-Za-z0-9_:]", "-- !ruby/object:RServiceBus::Message".length )[1]
        
        
        return hash
    end
    
    def run( env )
        request = Rack::Request.new(env)
        response = Rack::Response.new()
        
        path_list = request.path_info.split("/")
        request_name = path_list[1].downcase
        
        case true
            when request_name == "tube" && path_list.count == 2 then
            
                beanstalk = self.getBeanstalkConnection
                hash = beanstalk.list_tubes
                beanstalk.close
                list = hash[@beanstalkConnectionString]
            
                response.status = 200
                response.body = [list.to_json]
            


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

                    msg = convertRServiceBusMsgToHash(idx, job.body)
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
