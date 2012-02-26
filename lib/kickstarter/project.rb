module Kickstarter
  
  class Project
    
    attr_reader :node
    
    def initialize(node)
      @node = node
    end

    def handle
      @handle ||= url.split('/projects/').last
    end
    
    def name
      @name ||= link.inner_html
    end
    
    def description
      @description ||= node.css('h2 + p').inner_html
    end
    
    def url
      @url ||= File.join(Kickstarter::BASE_URL, link.attribute('href').to_s.split('?').first)
    end
    
    def owner
      @owner ||= node.css('h2 span').first.inner_html.gsub(/by/, "").strip
    end
    
    def email
    end
    
    def thumbnail_url
      @thumbnail_url ||= node.css('.project-thumbnail img').first.attribute('src').to_s
    end
    
    def pledge_amount
      @pledge_amount ||= /\$([0-9\,]+)/.match(node.css('.project-stats li')[1].css('strong').inner_html)[1].gsub(/\,/,"").to_i
    end
    
    def pledge_percent
      @pledge_percent ||= node.css('.project-stats li strong').inner_html.gsub(/\,/,"").to_i
    end
    
    # can be X days|hours left
    # or <strong>FUNDED</strong> Aug 12, 2011
    def pledge_deadline
      @pledge_deadline ||= begin
        date = node.css('.project-stats li').last.inner_html.to_s
        if date =~ /Funded/
          Date.parse date.split('<strong>Funded</strong>').last.strip
        elsif date =~ /hours? left/
          future = Time.now + date.match(/\d+/)[0].to_i * 60*60
          Date.parse(future.to_s)
        elsif date =~ /days left/
          Date.parse(Time.now.to_s) + date.match(/\d+/)[0].to_i
        elsif date =~ /minutes? left/
          future = Time.now + date.match(/\d+/)[0].to_i * 60
          Date.parse(future.to_s)
        end
      end
    end

    def to_hash
      {
        :name            => name,
        :handle          => handle,
        :url             => url,
        :description     => description,
        :owner           => owner,
        :pledge_amount   => pledge_amount,
        :pledge_percent  => pledge_percent,
        :pledge_deadline => pledge_deadline,
        :thumbnail_url   => thumbnail_url
      }
    end

    def inspect
      to_hash.inspect
    end
    
    # Details page
    def details_page
      @details_page ||= Project.fetch_details(url)
    end
    
    def pledge_goal
      @pledge_goal ||= Integer(/pledged of \$([0-9\.\,]+) goal/.match(details_page.css("#moneyraised").inner_html)[1].gsub(/,/,""))
    end
    
    def short_url
      @short_url ||= details_page.css("#share_a_link").attr("value").value
    end
    
    def about
      if @about.nil?
        node = details_page.css('#about')
        node.search("h3.dotty").remove
        @about = node.inner_html.to_s
      else
        @about
      end
    end
    
    def tiers
      retries = 0
      results = []
      begin
        nodes = details_page.css('.NS-projects-reward')
        nodes.each do |node|
          results << Kickstarter::Tier.new(node)
        end
      rescue Timeout::Error
        retries += 1
        retry if retries < 3
      end
      results
    end
    
    private
    
    def link
      node.css('h2 a').first
    end
    
    private
    
    def self.fetch_details(url)
      retries = 0
      begin
        Nokogiri::HTML(open(url))
      rescue Timeout::Error
        retries += 1
        retry if retries < 3
      end
    end
    
  end
  
end
