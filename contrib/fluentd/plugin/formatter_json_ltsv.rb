require_relative 'log_tags'
module Fluent
  module TextFormatter
    class LTSVFormatter1 < Formatter
      Plugin.register_formatter('json_ltsv', self)

   #   include Configurable # This enables the use of config_param
      include HandleTagAndTimeMixin # If you wish to use tag_key, time_key, etc.

   #   def configure(conf)
   #     super
   #   end
      config_param :delimiter, :string, :default => "\t"
      config_param :label_delimiter, :string, :default =>  ":"
def format(tag, time, record)
        filter_record(tag, time, record)
        formatted = $json_tag + record.inject('') { |result, pair|
          result << @delimiter if result.length.nonzero?
          result << "#{pair.first}#{@label_delimiter}#{pair.last}"
        }
        formatted << "\n"
        formatted
      end
    end
  end
end
