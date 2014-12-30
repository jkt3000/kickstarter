require 'rubygems'
require "nokogiri"
require 'open-uri'
require 'open_uri_redirections'
require 'date'
require "kickstarter/version"
require "kickstarter/project"
require "kickstarter/tier"

module Kickstarter
  BASE_URL = "http://www.kickstarter.com"  
  
  Categories = {
    :art         => "art",
    :comics      => "comics",
    :dance       => "dance",
    :design      => "design",
    :fashion     => "fashion",
    :film_video  => "film%20&%20video",
    :food        => "food",
    :games       => "games",
    :music       => "music",
    :photography => "photography",
    :publishing  => "publishing",
    :technology  => "technology",
    :theater     => "theater"
  }
  
  Types = {
    :popular     => 'popular',
    :recommended => 'recommended',
    :successful  => 'successful',
    :most_funded => 'most-funded'
  }
  
  Lists = {
    :recommended       => "recommended",
    :popular           => "popular",
    :recently_launched => "recently-launched",
    :ending_soon       => "ending-soon",
    :small_projects    => "small-projects",
    :most_funded       => "most-funded",
    :curated           => "curated-pages",
  }
  
  # by category
  # /discover/categories/:category/:subcategories 
  #  :type # => [recommended, popular, successful]
  def self.by_category(category, options = {})
    path = File.join(BASE_URL, 'discover/categories', Categories[category.to_sym], Types[options[:type] || :popular])
    list_projects(path, options)
  end
  
  # by lists
  # /discover/:list
  def self.by_list(list, options = {})
    path = File.join(BASE_URL, 'discover', Lists[list.to_sym])
    list_projects(path, options)
  end
  
  def self.by_url(url)
    Kickstarter::Project.new(url)
  end
  
  #https://www.kickstarter.com/discover/advanced?state=live&woe_id=23424977&raised=1&sort=end_date
  def self.by_list_ending_soon(options = {})
    new_path = "advanced?state=live&raised=1&sort=end_date"
    path = File.join(BASE_URL, 'discover', new_path)
    # list_projects(path, options)

    # TRYING TO WRITE MY OWN!
    pages = options.fetch(:pages, 0)
    pages = pages - 1 unless pages == 0 || pages == :all

    start_page = options.fetch(:page, 1)
    end_page = pages == :all ? 15 : start_page + pages

    results = []

    (start_page..end_page).each do |page|
      local_path = path + "&page=#{page}";

      nodes = Nokogiri::HTML(open(local_path, :allow_redirections => :safe)).css('.project')
      nodes.each do |node|
        results << Kickstarter::Project.new(node)
      end
    end
    results
  end

  private
  
  def self.list_projects(url, options = {})
    pages = options.fetch(:pages, 0)
    pages -= 1 unless pages == 0 || pages == :all

    start_page = options.fetch(:page, 1)
    end_page   = pages == :all ? 10000 : start_page + pages

    results = []

    (start_page..end_page).each do |page|
      retries = 0
      begin
        doc = Nokogiri::HTML(open("#{url}?page=#{page}", :allow_redirections => :safe))
        nodes = doc.css('.project')
        break if nodes.empty?

        nodes.each do |node|
          results << Kickstarter::Project.new(node)
        end
      rescue Timeout::Error
        retries += 1
        retry if retries < 3
      end
    end
    results
  end
end
