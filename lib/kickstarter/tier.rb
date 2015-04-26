module Kickstarter
  
  class Tier
    
    attr_reader :node
    
    def initialize(node)
      @node = node
    end
    
    def id
      @id ||= /backing\[backer_reward_id\]\=([0-9]+)/.match(node.css('h3 a').attr('href').value)[1].to_i
    end
    
    def minimum_pledge
      @minimum_pledge ||= Integer(node.css('span').text[/\$[0-9\.\,]+/].gsub(/\$/,"").gsub(/\,/,""))
    end
    
    def backer_count
      @backer_count ||= Integer(node.css(".num-backers").first.inner_html.gsub(/Backers?/,"").gsub(/\s+/,""))
    end
    
    def description
      @description ||= node.css('.desc').inner_html
    end
    
    def limited
      @limited ||= !limited_text.nil?
    end
    
    def limited_max
      @limited_max ||= limited ? Integer(/[0-9]+ of ([0-9]+) remaining/.match(limited_text)[1]) : nil
    end
    
    def limited_remaining
      @limited_remaining ||= limited ? Integer(/([0-9]+) of [0-9]+ remaining/.match(limited_text)[1]) : nil
    end
    
    def estimated_delivery
      if @estimated_delivery.nil?
        doc = node.css('.delivery-date')
        doc.search('strong').remove
        Date.parse doc.inner_html.gsub(/\n/,"")
      else
        @estimated_delivery
      end
    end
    
    def to_hash
      {
        :id                 => id,
        :minimum_pledge     => minimum_pledge,
        :backer_count       => backer_count,
        :description        => description,
        :limited            => limited,
        :limited_max        => limited_max,
        :limited_remaining  => limited_remaining,
        :estimated_delivery => estimated_delivery
      }
    end

    def inspect
      to_hash.inspect
    end
    
    private
    
    def limited_text
      @limited_text ||= node.css('.limited').text[/\([0-9]+ of [0-9]+ remaining\)/]
      @limited_text ||= node.css('.sold-out').text[/\([0-9]+ of [0-9]+ remaining\)/]
    end
    
  end
  
end