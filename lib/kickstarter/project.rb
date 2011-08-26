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
      @pledge_amount ||= node.css('.project-stats li')[1].css('strong').inner_html.gsub(/[^\d]/,'').to_i
    end
    
    def pledge_percent
      @pledge_percent ||= node.css('.project-stats li strong').inner_html.gsub(/\,/,"").to_i
    end
    


#     # can be X days|hours left
    # or <strong>FUNDED</strong> Aug 12, 2011
    def pledge_deadline
      @pledge_deadline ||= begin
        date = node.css('.project-stats li').last.inner_html.to_s
        if date =~ /Funded/
          Date.parse date.split('<strong>Funded</strong>').last.strip
        elsif date =~ /hours left/
          future = Time.now + date.match(/\d+/)[0].to_i * 60*60
          Date.parse(future.to_s)
        elsif date =~ /days left/
          Date.parse(Time.now.to_s) + date.match(/\d+/)[0].to_i
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
    
    private
    
    def link
      node.css('h2 a').first
    end
    
  end
  
end
