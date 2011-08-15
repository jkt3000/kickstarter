require 'rubygems'
require "nokogiri"
require 'open-uri'
require 'date'
require "./lib/kickstart/version"
require "./lib/kickstart/project"

module Kickstart
  BASE_URL = "http://kickstarter.com"  
  
  Categories = {
    :comics      => "Comics",
    :dance       => "Dance",
    :design      => "Design",
    :fashion     => "Fashion",
    :film_video  => "Film & Video",
    :fine_art    => "Fine Art",
    :food        => "Food",
    :games       => "Games",
    :music       => "Music",
    :photography => "Photography",
    :technology  => "Technology",
    :theatre     => "Theater",
    :writing     => "Writing & Publishing"
  }
  
  Type = {
    :recommended => 'recommended', 
    :popular => 'popular', 
    :successful => 'successful'
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
    path = File.join(BASE_URL, 'discover/categories', Categories[category.to_sym], Type[options[:type] || :popular])
    list_projects(path, options)
  end
  
  # by lists
  # /discover/:list
  def self.by_list(list, options = {})
    path = File.join(BASE_URL, 'discover', Lists[list.to_sym])
    list_projects(path, options)
  end
  
  private
  
  def self.list_projects(url, options = {})
    start_page = options.fetch(:page, 1)
    end_page   = start_page + options.fetch(:pages, 0)
    
    results = (start_page..end_page).map do |page| 
      doc = Nokogiri::HTML(open(url))
      doc.css('.project').map do |node|
        project = Kickstart::Project.new(node)
      end
    end
    results.flatten
  end
end
