=begin
Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Sensible Cinema is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Sensible Cinema is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Sensible Cinema.  If not, see <http://www.gnu.org/licenses/>.
=end

# shamelessly stolen from the redcar project

    class Storage
      class << self
        attr_writer :storage_dir
      end
    
      def self.storage_dir
        @user_dir ||= File.join(File.expand_path('~'), ".sensible_cinema_storage")
      end

      # Open a storage file or create it if it doesn't exist.
      #
      # @param [String] a (short) name, should be suitable for use as a filename
      def initialize(name)
        @name    = name
        unless File.exists?(Storage.storage_dir)
          FileUtils.mkdir_p(Storage.storage_dir)
        end
        rollback
      end

      # Save the storage to disk.
      def save
				File.open(path, "w") { |f| YAML.dump(@storage, f) }
        update_timestamp
        self
      end

      # Rollback the storage to the latest revision saved to disk or empty it if
      # it hasn't been saved.
      def rollback
        if File.exists?(path)
          @storage = YAML.load_file(path)
          unless @storage.is_a? Hash
            
            $stderr.puts 'storage file is corrupted--deleting ' + path 
            @storage = {}
            File.delete path
          end
          update_timestamp
        else
          @storage = {}
        end
        self
      end
      
      # retrieve key value
      # note: it does not re-read from disk before returning you this value
      def [](key)
        if @last_modified_time
          if File.exist?(path()) && (File.stat(path()).mtime != @last_modified_time)
            rollback
          end
        end
        @storage[key]
      end
      
      # set key to value
      # note: it automatically saves this to disk
      def []=(key, value)
        @storage[key] = value
        save
        value
      end
      
      def set_default(key, value)
        unless @storage.has_key?(key)
          self[key] = value
        end
        value
      end
      
      def keys
        @storage.keys
      end
      
      private
      
      def path
        File.join(Storage.storage_dir, @name + ".yaml")
      end
      
      def update_timestamp
        @last_modified_time = File.stat(path()).mtime
      end
    end
