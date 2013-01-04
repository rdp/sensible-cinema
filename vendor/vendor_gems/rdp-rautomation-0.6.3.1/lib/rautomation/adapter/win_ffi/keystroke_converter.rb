module RAutomation
  module Adapter
    module WinFfi
      class KeystrokeConverter
        class << self
          def convert(str)
            special_characters = ""

            str.split(/([{}])/).inject([]) do |converted_keys, str|
              if str == "}"
                converted_keys << convert_special_characters(special_characters << str)
                special_characters = ""
              elsif str == "{" || !special_characters.empty?
                special_characters << str
              else
                converted_keys += convert_characters(str)
              end
              converted_keys
            end.flatten
          end

          private

          def convert_special_characters chars
            case chars.downcase
            when "{tab}"
              Constants::VK_TAB
            when "{backspace}"
              Constants::VK_BACK
            when "{enter}"
              Constants::VK_RETURN
            when "{left}"
              Constants::VK_LEFT
            when "{right}"
              Constants::VK_RIGHT
            when "{down}"
              Constants::VK_DOWN
            when "{up}"
              Constants::VK_UP
            else
              # unsupported special tag, ignore the tag itself, but convert the
              # characters inside the tag
              convert_characters(chars.gsub(/[{}]/, ""))
            end
          end

          private

          def convert_characters(element)
            element.split(//).inject([]) do |chars, char|
              char_code = char.upcase.unpack("c")[0]
              if char =~ /[A-Z]/
                chars += in_upcase(char_code)
              else
                chars << char_code
              end
            end
          end

          def in_upcase(char_code)
            [Constants::VK_LSHIFT, char_code]
          end
        end
      end
    end
  end
end
