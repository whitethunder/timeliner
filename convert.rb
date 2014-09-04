#!/usr/bin/env ruby

require 'csv'
require 'redcarpet'
require 'set'

class TimelineGenerator
  attr_reader :csv_filename, :html, :markdown, :output_file, :tags, :timeline
  def initialize(input_file, output_file)
    @csv_filename = input_file
    @html = "\n<!-- BEGIN TIMELINE CONTENT -->\n"
    @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    @output_file = output_file
    @tags = Set.new
    @timeline = {}
  end

  def perform
    parse_csv
    generate_html
    write_to_file
  end

  private

  def parse_csv
    puts "Parsing #{csv_filename}..."
    CSV.foreach(csv_filename, headers: true) do |row|
      timeline[row['Date']] ||= []
      timeline[row['Date']] << row
      row['Tag'] && row['Tag'].split('/').each { |tag| tags << tag }
    end
  end

  def tag(tags)
    return '' unless tags
    tags.split('/').map { |tag| "[#{tag}]" }.join(' ')
  end

  def tag_classes(tags)
    return '' unless tags
    tags.split('/').map { |tag| "#{tag.downcase}-tag" }.join(' ')
  end

  def multiple_tags_classes(tags)
    return '' unless tags
    tags.map { |t| tag_classes(t) }.join(' ')
  end

  def generate_html
    html << "  <div class=\"tag_switch_container\">\n"
    tags.sort.each do |tag|
      html << "    <span class=\"tag_switch\">#{tag}</span>\n"
    end
    html << "  </div>\n"

    html << "\n  <div id=\"timelineContainer\" class=\"timelineContainer\">\n"

    timeline.keys.each do |date|
        html << <<-HTML
    <div class="timelineMajor #{ multiple_tags_classes(timeline[date].map { |row| row['Tag']}) }">
      <h2 class="timelineMajorMarker"><span>#{date}</span></h2>
        HTML
      timeline[date].each do |row|
        html << <<-HTML
      <dl class="timelineMinor #{tag_classes(row['Tag'])}">
        <dt><a>#{tag(row['Tag'])} #{row['Headline']}</a></dt>
        <dd class="timelineEvent" style="display: none;">
          #{markdown.render(row['Content'])}
        </dd>
      </dl>
        HTML
      end
      html << <<-HTML
    </div>
    <br class="clear">

      HTML
    end
    html << "  </div>\n"
    html << "<!-- END TIMELINE CONTENT -->\n"
  end

  def write_to_file
    puts "Writing to #{output_file}..."
    contents = File.read(output_file)
    contents.sub!(/\s*<!-- BEGIN TIMELINE CONTENT.+<!-- END TIMELINE CONTENT -->\s*/m, html)
    File.open(output_file, 'w') { |f| f.puts contents }
  end
end

puts "No input file specified" and exit if ARGV[0].nil?
puts "No output file specified" and exit if ARGV[1].nil?
TimelineGenerator.new(ARGV[0], ARGV[1]).perform