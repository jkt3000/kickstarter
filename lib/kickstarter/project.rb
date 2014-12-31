module Kickstarter
  
  class Project

    attr_reader :node
    
    def initialize(*args)
      case args[0]
      when String
        @seed_url = args[0]
      when Nokogiri::XML::Node
        @node = args[0]
      else
        raise TypeError
      end
    end
    
    def id
      @id ||= begin
        if node
          /\/projects\/([0-9]+)\/photo-little\.jpg/.match(thumbnail_url)[1].to_i 
        else
          details_page.css(".this_project_id").inner_html.to_i
        end
      end
    end
    
    def name
      # @name ||= node ? node_link.inner_html : details_page.css("#headrow h1#name a").inner_html
      @name ||= node.css('.project-title a')[0].children[0].text

    end
    
    def description
      @description ||= node ? node.css('h2 + p').inner_html : nil
    end
    
    def url
      @url ||= begin
        path = node ? node.css('.project-title a').attr('href').value.to_s : details_page.css("#headrow h1#name a").attr("href").value
        # path = node ? node_link.attribute('href').to_s : details_page.css("#headrow h1#name a").attr("href").value
        File.join(Kickstarter::BASE_URL, path.split('?').first)
      end
    end
    
    def category
      # @category ||= node.css('.category').attribute('data-project-parent-category').value.strip
      # @category ||= details_page.css('.category a').children[1].text.strip

      c_array = details_page.css('.grey-dark').css('.mr3').css('.nowrap')[1].attribute('href').value[21..-14].split('/')
      if (c_array.length > 1)
        c_array[0] = c_array[0].split('%20').each { |c| c.capitalize! }.join(' ')
        c_array[1] = c_array[1].split('%20').each { |c| c.capitalize! }.join(' ')
        @category ||= c_array.join('/')
      else
        @category ||= c_array.first.capitalize
      end
    end

    def handle
      @handle ||= url.split('/projects/').last.gsub(/\/$/,"")
    end
    
    def owner
      @owner ||= begin
        if node
          # node.css('h2 span').first.inner_html.gsub(/by/, "").strip
          # node.css('.project-card-interior p').children[0].text[4..-2]
          node.css('.project-byline').children.text[4..-2]
        end
      end
    end
    
    def thumbnail_url
      @thumbnail_url ||= begin
        if node
          node.css('.project-thumbnail img').attribute('src').value
        end
      end
    end
    
    def pledge_amount
      @pledge_amount ||= begin
        if node
          /\$([0-9\,]+)/.match(node.css('.project-stats li')[1].css('strong').inner_html)[1].gsub(/\,/,"").to_i
        else
          Integer(details_page.css("#moneyraised h5")[1].css(".num").inner_html.gsub(/,|\$/,""))
        end
      end
    end
    
    def pledge_percent
      @pledge_percent ||= begin
        if node
          node.css('.project-stats li strong').inner_html.gsub(/\,/,"").to_i * 1.0
        else
          pledge_amount * 1.0 / pledge_goal * 100.0
        end
      end
    end
    
    # can be X days|hours left
    # or <strong>FUNDED</strong> Aug 12, 2011
    def pledge_deadline
      if node
        @pledge_deadline ||= Time.parse(node.css(".ksr_page_timer").attr("data-end_time").value)
      else
        @pledge_deadline ||= exact_pledge_deadline.to_date
      end
    end

    def to_hash
      node_values = {
        :id              => id,
        :name            => name,
        :handle          => handle,
        :url             => url,
        :category        => category,
        :description     => description,
        :owner           => owner,
        :pledge_amount   => pledge_amount,
        :pledge_percent  => pledge_percent,
        :pledge_deadline => pledge_deadline.to_s,
        :thumbnail_url   => thumbnail_url,
        :short_url       => short_url
      }
      if node.nil? #we are working with the details page only
        extra_values = {
          :pledge_goal            => pledge_goal,
          :exact_pledge_deadline  => exact_pledge_deadline.to_s,
          :short_url              => short_url,
          :about                  => about,
          :tiers                  => tiers.map{|t|t.to_hash}
        }
        node_values = node_values.merge(extra_values)
      end
      node_values
    end

    def inspect
      to_hash.inspect
    end
    
    #######################################################
    # Methods below *REQUIRE* a fetch of the details page #
    
    def details_page
      @details_page ||= seed_url ? Project.fetch_details(seed_url) : Project.fetch_details(url)
    end
    
    def pledge_goal
      @pledge_goal ||= Integer(/pledged of \$([0-9\.\,]+) goal/.match(node.css("#moneyraised").inner_html)[1].gsub(/,/,""))
    end
    
    def exact_pledge_deadline
      @exact_pledge_deadline ||= Time.parse(details_page.css(".ksr_page_timer").attr("data-end_time").value)
    end
    
    # Note: Not all projects are assigned short_urls.
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
    
    #######################################################
    private
    #######################################################
    
    attr_reader :seed_url
    
    def node_link
      # node.css('h2 a').first
      node.css('project-title a').first
    end
    
    def self.fetch_details(url)
      retries = 0
      begin
        Nokogiri::HTML(open(url, :allow_redirections => :safe))
      rescue Timeout::Error
        retries += 1
        retry if retries < 3
      end
    end
    
  end
  
end
