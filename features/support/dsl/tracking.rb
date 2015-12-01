require 'yaml'
require 'open-uri'      # included with Ruby; only needed to load HTML from a URL
require 'nokogiri'      # gem install nokogiri   read more at http://nokogiri.org
require 'json'


module Everjobs
  module Dsl
    def get_tracking_request()
      request_regex = Regexp.new("http.?://zalora01.webtrekk(.*).net(.*)")
      files_sorted_by_time = Dir[$build_dir + '/*.har'].sort_by{ |f| File.mtime(f) }.last
      File.open(files_sorted_by_time).each_line do |line|
        request = line if (line[request_regex])
        if !(request == nil)
          request = request.strip.downcase
          File.open($build_dir+'/webtrekk_tracking_request.yml','w') { |f|
            f.write(request.to_yaml)
          }
        end
      end
    end


    def save_webtrekk_part_to_file
      regex = Regexp.new("Webtrekk begin(.*?(\n))+.*? Webtrekk End")
      doc = page.html
      File.open($build_dir+'/trackingJSwebtrekk.yml','w') { |f|
        f.write(doc[regex].to_s)
      }

    end

    def check_Tracking_Code(webtrekk_part,key, expected_value, source)
      file = File.open($build_dir+'/trackingJSwebtrekk.yml')
      content = file.read
      result_form = ''
      elements = 0

      case webtrekk_part
        when 'WtProjectConfig'
          regex = /\webtrekkProjectConfig = {(.*?)\}/m
          result_form = 'json'
          elements = 4
        when 'WtContentId'
          regex = /\wt.contentId = (.*?)[\s\+\s]/m
        when 'WtContentGroup'
          regex = /\wt.contentGroup = {(.*?)\}/m
          result_form = 'json'
          elements = 10
        when 'WtCustomerId'
          regex = /\wt.customerId = (.*?)\;/m
        when 'WtInternalSearch'
          regex = /\wt.internalSearch = (.*?)\;/m
        when 'WtCustomSessionParameter'
          regex = /\wt.customSessionParameter = {(.*?)\}/m
          result_form = 'json'
          elements = 3
        when 'WtCustomParameter'
          regex = /\wt.customParameter = {(.*?)\}/m
          result_form = 'json'
          elements = 5
        when 'WtCustomCampaignParameter'
          regex = /\wt.customCampaignParameter={(.*?)\}/m
          result_form = 'json'
          elements = 6
        when 'WtProduct'
          regex = /\wt.product = \"(.*?)\"\;/
        when 'WtProductStatus'
          regex = /\wt.productStatus = (.*?)\;/m
        when 'WtProductCost'
          regex = /\wt.productCost = \"(.*?)\"\;/
        when 'WtProductQuantity'
          regex = /\wt.productQuantity = \"(.*?)\"\;/
        when 'WtProductCategory'
          regex = /\wt.productCategory={(.*?)\}/m
          result_form = 'json'
          elements = 4
        when 'WtCustomEcommerceParameter'
          regex = /\wt.customEcommerceParameter = {(.*?)\}/m
          result_form = 'json'
          elements = 12
        when 'WtOrderValue'
          regex = /\wt.orderValue = \"(.*?)\"\;/
        when 'WtOrderId'
          regex = /\wt.orderId = \"(.*?)\"\;/
        else
          regex = /(.*)/m
      end

      trekkingPart = content.scan(regex)
      extract_and_check_tracking_values(webtrekk_part,elements, trekkingPart,result_form, key, expected_value, source)
      file.close

    end

    def extract_and_check_tracking_values(webtrekk_part, elements, array, format, key, expectedValue, source)
      #webtrekk via json format
      if format == 'json'
        a = 1
        array.each do |elem|
          until a == elements+1
            if elem[0].split(",")[a-1]!=nil
              if elem[0].split(",")[a-1].split(":")[1] !=nil
                checkValue =  elem[0].split(",")[a-1].split(":")[1].gsub(/("|')/,'').strip
                number = elem[0].split(",")[a-1].split(":")[0].strip.to_i
                if key.to_i == number
                  if checkValue!=nil
                    puts "check " + webtrekk_part + " parameter " + number.to_s + ",Found value: " + checkValue
                    if source== 'source code'
                      if checkValue.to_s.downcase.strip.eql? expectedValue.to_s.strip.downcase
                        puts "successful"
                      else
                        raise ("20.6 Check failed! Expected: " + expectedValue.to_s.downcase.strip + ", Found: " + checkValue.to_s.strip.downcase)
                      end
                    else
                       checkRequest = File.open($build_dir+'/webtrekk_tracking_request.yml','r').grep(/#{expectedValue.downcase.strip.to_s}/)
                       if checkRequest.length > 0
                         puts "successful"
                       else
                         raise ("Check failed! Expected value (" + expectedValue + ") not found in request")
                       end
                    end
                  end
                end
              end
            end
            a += 1
          end
        end
      else
        #webtrekk via hashmap
        array.each do |elem|
          checkValue = elem[0].gsub('"','').strip
          puts "check " +webtrekk_part + ",Found value: " + checkValue
          if source== 'source code'
            if checkValue.downcase.to_s.eql? expectedValue.downcase.to_s
              puts "successful"
            else
              if webtrekk_part == 'WtProductCost'
                puts 'Check failed! Expected: ' + expectedValue + ', Found: ' + checkValue
              else
                raise ('Check failed! Expected: ' + expectedValue + ', Found: ' + checkValue)
              end
            end
          else
            checkRequest = File.open($build_dir+'/webtrekk_tracking_request.yml','r').grep(/#{expectedValue.downcase.to_s}/)

            if checkRequest.length > 0
              puts "successful"
            else
              if webtrekk_part == 'WtProductCost'
                puts ('Check failed! Expected value (' + expectedValue + ') not found in request')
              else
                raise ('Check failed! Expected value (' + expectedValue + ') not found in request')
              end
            end
          end
        end
      end
    end

    def get_webtrekk_trackId
      file = File.open($build_dir+'/trackingJS.yml')
      content = file.read
      regex = /trackId : "(.*?)"\,/m
      array = content.scan(regex)
      trackId = array.to_s.gsub('"','').gsub('[','').gsub(']','').strip
      puts "check trackId" + " - " + trackId
      return trackId
    end

    def save_to_file(pixel)
      #no use <-- in regex patterns, because in test env they change to "||" for safe statistic
      case pixel
        when 'webtrekk'
          #pattern = "Webtrekk begin(.*?(\n))+.*? Webtrekk end"
          pattern = "var webtrekkProjectConfig(.*?(\n))+.*?"
        when 'ga'
          pattern = "Google Analytics begin(.*?(\n))+.*? Google Analytics end"
        when 'tyroo'
          pattern = "var affiliateAttribution(.*?(\n))</script>"
      end
      regex = Regexp.new(pattern)
      doc = page.html
      content = doc[regex]
      content = content.to_s
      if content.length == 0
        raise ('Pixel ' + pixel + ' not found')
      end
      File.open($build_dir+'/trackingJS'+pixel+'.yml','w') { |f|
        f.write(content)
      }
    end

    def get_webtrekk_parameter(parameterName)
      content = get_tracking_text('webtrekk')
      case parameterName
        when 'trackId'
          regex = /trackId\s?:\s?"(.*?)"\,/m
        when "wt.product"
          regex = /wt.product\s?=\s?"(.*?)";/m
        when 'wt.contentId'
          regex = /wt.contentId\s?=\s?"(.*?)";/m
      end
      result = content.scan(regex)

      if result.is_a? Array
        result = result.to_s.gsub('"','').gsub('[','').gsub(']','').strip
      end

      result
    end

    def get_google_analytics_parameter(parameterName)
      content = get_tracking_text('ga')
      regex = /\['#{parameterName}',\s*'(.*?)'\]/m;
      result = content.scan(regex).to_s.gsub('"','').gsub('[','').gsub(']','').strip
      result
    end

    def get_tracking_text(pixel)
      File.open($build_dir+'/trackingJS'+pixel+'.yml').read
    end
  end
end
