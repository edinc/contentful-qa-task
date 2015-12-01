# encoding: utf-8
require 'singleton'
require 'ibanizator'
require 'securerandom'


class Fixtures
  include Singleton

  attr_reader :unique_random_number, :timestamp, :last_timestamp, :last_used_email, :last_used_email2, :form_handler
  attr_accessor :scenario

  FIXTURES_DIR       =File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'fixtures', ENV['CUCUMBER_ENV'] ? ENV['CUCUMBER_ENV'] : 'default')
  MAX_FILENAME_LENGTH=345

  def self.instance
    @@instance ||= new
  end

  def initialize

    @unique_random_number = random_number
    @email_zencap_qa_random_number = random_number
    @last_timestamp = nil
    @timestamp = Time.new.to_i
    @form_handler = FormHandler.instance @timestamp
  end

  def fill_form_by_fixtures form_data
    form_handler.fill_form_by_fixtures form_data
  end

  def data_for data_sym
    return nil if data_sym.nil?

    @data[data_sym]
  end

  def remove_data_for data_sym,entry
    @data[data_sym].delete entry
  end

  def randomize_email_address email_address
    email_address = email_address.first.to_s if email_address.is_a? Array

    email_address_parts = email_address.split("@")
    prefix = email_address_parts.first

    if prefix.include? "+"
      prefix << random_number.to_s
    else
      prefix << "+" << random_number.to_s
    end

    prefix << "@" << email_address_parts.last
  end

  def [] fixture_name
    self.send(fixture_name.to_sym)
  end

  def email
    @last_used_email = "#{@unique_random_number}.#{@timestamp}@#{test_email_provider}"
  end

  def random_number
    (SecureRandom.random_number * 10000000).to_i
  end

  def random_letters length=20
    Array.new(length){[*'a'..'z', *'A'..'Z'].sample}.join
  end


  alias_method :unique_random_email_address, :email
  alias_method :unique_email_address, :email
  alias_method :scenario_stable_unique_email_address, :email
  alias_method :scenario_reusable_unique_testmarked_email, :email

  def email2
    @last_used_email2  = "#{@unique_random_number}.2_#{@timestamp}@#{test_email_provider}"
  end

  def timestamp_qa
    @timestamp_qa  = @timestamp
  end

  alias_method :unique_random_email2_address, :email2
  alias_method :scenario_reusable_unique_testmarked_email2, :email2

  def iban_qa
    if @iban==nil
      ibanizator = Ibanizator.new
      @iban = ibanizator.calculate_iban country_code: :de, bank_code: '10000000', account_number: "#{@timestamp}"
    end
    @iban
  end
  alias_method :unique_random_iban_qa, :iban_qa

  def number_qa
    time = Time.new
    hour = time.strftime("%I")
    temp = (hour.to_i % 6) + 1
    last_number= "0" + temp.to_s
    @number_qa = "004916200000" + last_number
  end

  def number_qa2
    time = Time.new
    hour = time.strftime("%I")
    temp = (hour.to_i % 6) + 7
    if temp.to_i < 10
      last_number = "0" + temp.to_s
    else
      last_number = temp.to_s
    end
    @number_qa = "004916200000" + last_number
  end

  def voucher_qa
    "#{@timestamp}_TestautoVouchersTest"
  end
  alias_method :scenario_reusable_random_voucher, :voucher_qa

  def firstname
    "#{testcase_identifier_prefix}#{@timestamp}"
  end

  def firstname_letters_only
    "#{testcase_identifier_prefix}" + @timestamp.to_s.tr('0-9','a-z')
  end

  def random_full_user_name
    @timestamp.to_s.tr('0-9','a-z') + " Everjobs"
  end

  alias_method :scenario_stable_unique_firstname, :firstname
  alias_method :scenario_stable_unique_firstname, :firstname
  alias_method :scenario_reusable_unique_testmarked_firstname, :firstname

  def lastname
    "#{testcase_identifier_prefix}last_#{@timestamp}"
  end

  alias_method :scenario_stable_unique_lastname, :lastname
  alias_method :scenario_reusable_unique_testmarked_lastname, :lastname

  def firstname2
    "#{testcase_identifier_prefix}2_#{@timestamp}"
  end

  alias_method :scenario_stable_unique_firstname2, :firstname2
  alias_method :scenario_reusable_unique_testmarked_firstname2, :firstname2

  def lastname2
    "#{testcase_identifier_prefix}last_2_#{@timestamp}"
  end

  alias_method :scenario_stable_unique_lastname2, :lastname2
  alias_method :scenario_reusable_unique_testmarked_lastname2, :lastname2

  def category
    "#{testcase_identifier_prefix}category_#{@timestamp}"
  end

  alias_method :scenario_stable_unique_category_name, :category
  alias_method :scenario_reusable_unique_testmarked_category, :category

  def testcase_identifier_prefix
    Configuration.fetch('fixtures.testcase_identifier_prefix', 'test_')
  end

  alias_method :test_prefix, :testcase_identifier_prefix

  # postfix not used at the moment!
  #def testcase_identifier_postfix
  #  Configuration.fetch('fixtures.testcase_identifier_postfix', '_test')
  #end

  def products_highest_stock
    if @products_highest_stock == nil
      file = File.join(FIXTURES_DIR, 'highest_stock_products.yml')
      if File.exists? file
        @products_highest_stock = begin
          YAML.load(File.open(file))
        rescue ArgumentError => e
          puts "Could not parse YAML: #{e.message}"
        end
      else
        puts "Fixture '#{file}' is missing."
      end
    end
    @products_highest_stock
  end

  # num starts at 1!! [0] is undefined although it could exists
  def given_product num
    #FIXME: only till issue in AUT is fixed: config.yml precedes highest_stock, if fixed other way round
    #TODO: Fix had been made, but will remove the out commented code, when the function functions well.
    #prods = Configuration.fetch("fixtures.products", nil)
    #if prods
    #  prods[num-1]
    #else
    #  prods = products_highest_stock
    #  if prods
    #    prods[num]
    # else
    #    nil
    #  end
    #end

    prods = products_highest_stock
    if prods
      prods[num]
    else
      prods = Configuration.fetch("fixtures.products", nil)
      if prods
        prods[num-1]
      else
       nil
      end
    end
  end

  #called in After scenario hook
  def next_scenario
    @last_timestamp = @timestamp
    @timestamp = Time.new.to_i
  end

  def scenario_build_dir()
    FileUtils.mkdir_p(@scenario_build_dir)
    return @scenario_build_dir
  end

  def scenario_build_dir=(scenario_build_dir)
    if scenario_build_dir.length > MAX_FILENAME_LENGTH
      @scenario_build_dir = scenario_build_dir[0,MAX_FILENAME_LENGTH]
    else
      @scenario_build_dir = scenario_build_dir
    end
  end

  #deprecated Fixture files are now to be stored project-specific in profiles/(profile_ | '')common/step_definitions/support/fixtures/(ENV["CUCUKBER_ENV"])
  def get_file_fixture_path(name)
    if name.to_s.downcase.end_with?('.csv')
      return File.join(FIXTURES_DIR, 'csv', name)
    elsif name.to_s.downcase.end_with?('.jpg')
      return get_image_fixture_path(name)
    end
    File.join(FIXTURES_DIR, name)
  end

  def get_image_fixture_path(name)
    File.join(FIXTURES_DIR, 'img', name)
  end

  #fall back to fixtures in config.yml
  def method_missing(sym, *args, &block)
    if sym.to_s.start_with? 'urls.'
      return Configuration.fetch("#{sym}", '')
    else
      return Configuration.fetch("fixtures.#{sym}", '')
    end
  end

  protected

  def test_email_provider
    Configuration.fetch("fixtures.test_email_provider", 'mailinator.com')
  end

  # this is profile depend and has to be defined in the config.yml/<profile>/fixtures!!!
  # YAML spec: http://yaml.org/spec/1.1/#id931088
  # see default/fixtures/stock_ok_array for example of array definition in YAML
  #def stock_ok_array
  #  [ 'In stock','Stok tersedia','มีสินค้า','Còn hàng', 'Còn nhiều hàng','暢銷商品搶購中','Currently available','ขณะนี้ยังมีสินค้า']
  #end
end

def xss_not_found
  page.driver.browser.switch_to.alert.accept
  raise "Alert was found! XSS-Attack was successful!"
rescue Selenium::WebDriver::Error::NoAlertPresentError
  # pass
end
