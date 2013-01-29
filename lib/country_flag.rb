module CountryFlag
  # To change this template use File | Settings | File Templates.
  class << self

    def load
      path = Rails.root.join('app', 'assets','images','icons','flags')
      flags = []
      ignore_dirs = [ '.', '..' ]
      Dir.foreach(path) do |filename|
        f = File.basename(filename)
        if File.directory?(filename) ||
            ignore_dirs.include?(f)
          next
        end
        flags.push( [ f[/[^\.]+/], :value => f] )
      end
      flags
    end

  end
end