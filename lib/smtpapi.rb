$LOAD_PATH.unshift File.dirname(__FILE__)
require 'smtpapi/version'
require 'json'

module Smtpapi
  #
  # SendGrid smtpapi header implementation
  #
  class Header
    attr_reader :to, :sub, :section, :category, :unique_args, :filters
    attr_reader :send_at, :send_each_at, :asm_group_id, :ip_pool

    def initialize
      @to = []
      @sub = {}
      @section = {}
      @category = []
      @unique_args = {}
      @filters = {}
      @send_at = nil
      @send_each_at = []
      @asm_group_id = nil
      @ip_pool = nil
    end

    def add_to(address, name = nil)
      if address.is_a?(Array)
        @to.concat(address)
      else
        value = address
        value = "#{name} <#{address}>" unless name.nil?
        @to.push(value)
      end
      self
    end

    def set_tos(addresses)
      @to = addresses
      self
    end

    def add_substitution(sub, values)
      @sub[sub] = values
      self
    end

    def set_substitutions(key_value_pairs)
      @sub = key_value_pairs
      self
    end

    def add_section(key, value)
      @section[key] = value
      self
    end

    def set_sections(key_value_pairs)
      @section = key_value_pairs
      self
    end

    def add_unique_arg(key, value)
      @unique_args[key] = value
      self
    end

    def set_unique_args(key_value_pairs)
      @unique_args = key_value_pairs
      self
    end

    def add_category(category)
      @category.push(category)
      self
    end

    def set_categories(categories)
      @category = categories
      self
    end

    def add_filter(filter_name, parameter_name, parameter_value)
      @filters[filter_name] = {} if @filters[filter_name].nil?
      @filters[filter_name]['settings'] = {} if @filters[filter_name]['settings'].nil?
      @filters[filter_name]['settings'][parameter_name] = parameter_value
      self
    end

    def set_filters(filters)
      @filters = filters
      self
    end

    def set_send_at(send_at)
      @send_at = send_at
      self
    end

    def set_send_each_at(send_each_at)
      @send_each_at = send_each_at
      self
    end

    def set_asm_group(group_id)
      @asm_group_id = group_id
      self
    end

    def set_ip_pool(pool_name)
      @ip_pool = pool_name
      self
    end

    def json_string
      escape_unicode(to_array.to_json)
    end
    alias_method :to_json, :json_string

    def escape_unicode(str)
      str.unpack('U*').map { |i| format_char(i) }.join
    end

    protected

    def to_array
      data = {}
      
      headers = %w[to sub section unique_args category filters ip_pool]
      headers.each do |header|
        data[header] = instance_variable_get("@#{header}")
      end

      data['send_at'] = @send_at && @send_at.to_i
      data['asm_group_id'] = @asm_group_id && @asm_group_id.to_i
      data['send_each_at'] = @send_each_at.map(&:to_i)

      data.reject { |_, val| valid_value?(val) }
    end

    private

    def format_char(ch)
      if ch > 65_535
        "\\u#{unicode_char(ch, 1)}\\u#{unicode_char(ch, 2)}"
      elsif ch > 127
        "\\u#{unicode_char(ch, 3)}"
      else
        ch.chr('UTF-8')
      end
    end

    def unicode_char(ch, n)
      if n == 1
        ch = (ch - 0x10000) / 0x400 + 0xD800
      elsif n == 2
        ch = (ch - 0x10000) % 0x400 + 0xDC00
      end
      format('%04x', ch)
    end

    def valid_value?(val)
      val.nil? || (!val.is_a?(Integer) && val.empty?)
    end
  end
end
