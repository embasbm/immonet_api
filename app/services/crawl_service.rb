class CrawlService
  def initialize(rooms, city)
    @agent    = Mechanize.new
    @root_url = 'https://www.immonet.de'
    @rooms    = rooms || 1
    @city     = city || 'Hamburg'
    @max_rent_amount = 600
    log_in
  end

  def log_in
    signin_page = @agent.get('https://www.immonet.de/immonet/logon.do')
    @my_page = signin_page.form_with(:name => 'loginForm') do |login_form|
      login_form.username = ENV["monnit_username"]
      login_form.password = ENV["monnit_password"]
    end.submit
    search_flats
  end

  def search_flats
    home_page = @agent.get('https://www.immonet.de/wohnung-mieten.html')
    @my_flats = home_page.form_with(:name => 'FilterListForm') do |search_form|
      search_form.locationname  = @city
      search_form.toprice       = @max_rent_amount
      search_form.parentcat     = 100 # => fully furnished
      search_form.fromrooms     = 1
    end.submit
    collect_listings
    crawl_listings
  end

  def collect_listings
    @flats_links = @my_flats.links_with(:href => /angebot/).collect { |link| link.href }.uniq
    @my_flats.links_with(:href => /page/, :text => /\d/ ).each do |page_link|
      page = @agent.get(page_link.href)
      @flats_links += page.links_with(:href => /angebot/).collect { |link| link.href }.uniq
    end
    @flats_links.flatten!
  end

  def crawl_listings
    return if @flats_links.blank?
    @flats_links.each do |flat_link|
      flat_page = @agent.get(flat_link)
      contact_flat_form flat_page
    end
  end

  def contact_flat_form(flat_page)
    contact_form = flat_page.form_with(:name => 'sbc_contactForm')
    contact_form['contactForm.salutation']   = 'Herr'
    contact_form['contactForm.prename']      = 'Emba'
    contact_form['contactForm.surname']      = 'embasbm'
    contact_form['contactForm.email']        = 'embasbm@gmail.com'
    contact_form['contactForm.phone']        = '+34611430107'
    contact_form['contactForm.street']       = 'Osio Kalea'
    contact_form['contactForm.zip']          = '20820'
    contact_form['contactForm.city']         = 'Gipuzkoa'
    contact_form['contactForm.annotations']  = 'First of all, I am so sorry I do not speak any German, yet. I am coming to Hamburg to start a new role as Software Developer at a Startup called EventInc (I can provide any Docs realet to the contracts and etc). I am looking for a place and would love to have a chat about the place you offering here. Please drop me a ine on the phone, or send me an email. Many thanks'
    contact_form['contactForm.privacy']      = 'true'
    result_page = contact_form.submit
  end
end
# => CrawlService.new(1,'Hamburg')
