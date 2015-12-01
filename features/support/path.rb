#path mapper to translate strings like "homepage" or "login page" to a path

module NavigationHelpers
  def path_to(page_name)
    case page_name
      when /catalog page/
        '/all-products/'
      when /all products page/
        '/all-products/'
      when /homepage/
        '/'
      when /nike page/
        '/Baju-Sepakbola/nike/'
      when /contact page/
        '/contact/'
      else
        # '' is for returning a copy otherwise manipulation will modify the Configuration object contents!!
        return  Configuration.fetch("urls.#{page_name.pathify}", page_name)
    end
  end
end

World(NavigationHelpers)
