module Uploads
  module Fs
    class << self

      def get_public_dir
        Rails.root.join('public').to_s
      end

      def get_upload_dir
        Rails.root.join('public', 'uploads')
      end

      def get_cache_dir
        path = Rails.root.join('public', 'cache')
        if(!Dir.exists?(path))
          FileUtils.mkdir_p path
        end
        path
      end

      def setup_cache_dir(agency_id)
        path = Rails.root.join('public', 'cache', String(agency_id))
        if(!Dir.exists?(path))
          FileUtils.mkdir_p path
        end
        path
      end

      def create_if_not_exists(path, endpoint)
        _path = path.join(endpoint)
        if !Dir.exists?(_path)
          FileUtils.mkdir_p _path
        end
        _path
      end

      def create_path_if_not_exists(path)
        if !Dir.exists? path
          FileUtils.mkdir_p path
        end
        path
      end

      def fetch_file_under_path(path, filename, mode = nil, mask = 0644)
        mode ||= File::CREAT|File::TRUNC|File::RDWR
        path = (path.class == String) ? Pathname.new(path) : path
        # TODO : check mask validity
        _filename = "%s/%s" % [path.to_s, filename]
        if File.exists? _filename
          File.open(_filename, mode)
        else
          File.new(_filename, mode, mask)
        end
      end

      def flush_dir_for_agency(agency_id)
        true
      end

      def create_agency_dir(agency)
        uploads_root = Pathname.new(get_uploads_root)
        if Dir.exists?(uploads_root.join(String(agency.id)))
          raise IOError.new('A directory already exists for an agency with the same id')
        end
        FileUtils.mkdir_p uploads_root.join(String(agency.id), 'logo')
        FileUtils.mkdir_p uploads_root.join(String(agency.id), 'docs')
        FileUtils.mkdir_p uploads_root.join(String(agency.id), 'private')
        FileUtils.mkdir_p uploads_root.join(String(agency.id), 'public')
        FileUtils.mkdir_p uploads_root.join(String(agency.id), 'objects')
        FileUtils.mkdir_p uploads_root.join(String(agency.id), 'tmp')

        uploads_root.join(String(agency.id))
      end

      def get_root_path_for_agency(agency)
        Rails.root.join('public', 'uploads', 'clients', String(agency.id))
      end

      def write_on_fs(upload_file, agency, agency_root_path)
        name = upload_file.original_filename
        directory = Pathname.new(agency_root_path)
        new_filename = "%s%s" % [String(agency.id), File.extname(name)]
        path = File.join(directory.join('logo'), new_filename)
        File.open(path, "wb") { |f| f.write(upload_file.read) }
        new_filename
      end

      private

      def get_uploads_root
        upload_dirname = Rails.root.join('public', 'uploads')
        if !Dir.exists?(upload_dirname)
          Dir.mkdir(upload_dirname)
        end
        uploads_clients_dirname = Rails.root.join('public', 'uploads', 'clients')
        if !Dir.exists? uploads_clients_dirname
          Dir.mkdir uploads_clients_dirname
        end
        uploads_clients_dirname
      end
    end
  end

  class Helper

    def initialize

    end

    def self.clean_url(url)
      {
          '!' => '%21',
          '#' => '%23',
          '$' => '%24',
          '&' => '%26',
          '\'' => '%27',
          '(' => '%28',
          ')' => '%29',
          '*' => '%2A',
          '+' => '%2B',
          ',' => '%2C',
          '/' => '%2F',
          ':' => '%3A',
          ';' => '%3B',
          '=' => '%3D',
          '?' => '%3F',
          '@' => '%40',
          '[' => '%5B',
          ']' => '%5D'
      }.each{ |k,v|
        url = url.gsub(k,v)
      }
      url
    end
  end
end