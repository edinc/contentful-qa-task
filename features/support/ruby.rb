#escape strings for usage as a file system path
#e.g. replace blanks with a '_' in order to generate a key that is usable with the url configs in config.yml.
class String
  def pathify
    return self.gsub(/[^a-zA-Z0-9]/, '_').gsub(/^_*|_*$/, '')
  end

  def escape_xpath
    if self =~ /'/
      return self.gsub(/'/, %[', "'", ']) + %[')] # horribly, this is how you escape single quotes in XPath.
    else
      %['#{self}']
    end
  end

  def ucfirst
    self.gsub(/(\w+)/) { |s| s.capitalize }
  end

  def ucfirst!
    self.gsub!(/(\w+)/) { |s| s.capitalize }
  end
end
