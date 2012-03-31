#!/usr/bin/env ruby

=begin

download image of the day from nasa's rss feed, resize it according to
MAX_W and MAX_H, and composit it (along with the title) on a black
image of size IMG_W x IMG_H.

=end

# url to rss feed
URL   = 'http://www.nasa.gov/rss/image_of_the_day.rss'
# size of final (composited) image
IMG_W = 1600
IMG_H = 900
# max size of source image
MAX_W = IMG_W
MAX_H = 700


require 'hpricot'
require 'rest-open-uri'
require 'RMagick'

# get info about image
rss   = Hpricot(open(URL))
item  = rss .search("item")     [0]
title = item.search("title")    [0].inner_html
image = item.search("enclosure")[0].get_attribute('url')

# download image
puts "downloading #{image} ..."
source = File.basename(image)
open(source, 'wb') << open(image).read

# create black background
bg = Magick::Image.new(IMG_W, IMG_H) do
  self.background_color = 'black'
end

# resize source image
img = Magick::Image.read(source).first
img.change_geometry!("#{MAX_W}x#{MAX_H}") { | cols, rows, img | img.resize!(cols, rows) }
# composit on bg
iw = img.columns
ih = img.rows
ix = (bg.columns - iw) / 2
iy = (bg.rows    - ih)    / 2
bg.composite!(img, ix, iy, Magick::OverCompositeOp)

# add title
draw = Magick::Draw.new
draw.annotate(bg, 0, 0, 10, 10, title) {
  self.gravity = Magick::SouthEastGravity
  self.font_family = 'Arial'
  self.pointsize   = 24
  self.fill        = 'white'
  self.stroke      = 'none'
}

# add border
draw.stroke = 'white'
draw.fill   = 'none'
draw.rectangle(ix-1, iy-1, ix+iw+2, iy+ih+2)
draw.draw(bg)

#write result to file
bg.write('bg_'+source)
