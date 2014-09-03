#!/usr/bin/env ruby

require 'csv'
require 'redcarpet'
require 'set'

class TimelineGenerator
  attr_reader :csv_filename, :html, :markdown, :output_file, :timeline
  def initialize(input_file, output_file)
    @csv_filename = input_file
    @html = "\n<!-- BEGIN TIMELINE CONTENT -->\n"
    @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    @output_file = output_file
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
    end
  end

  def tag_output(tags)
    return '' unless tags
    tags.split('/').map { |tag| "[#{tag}]" }.join(' ')
  end

  def generate_html
    timeline.keys.each do |date|
        html << <<-HTML
    <div class="timelineMajor">
      <h2 class="timelineMajorMarker"><span>#{date}</span></h2>
        HTML
      timeline[date].each do |row|
        html << <<-HTML
      <dl class="timelineMinor">
        <dt><a>#{tag_output(row['Tag'])} #{row['Headline']}</a></dt>
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