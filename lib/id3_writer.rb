require 'taglib'
require 'ruby-pinyin'

class ID3Writer
  def self.write_id3(path, info)
    # info:
    #
    # {
    #   artist:
    #   album:
    #   title:
    #   album_artist:
    #   genre:
    #   track:
    #   disc:
    #   year:
    #   cover:
    # }

    [:artist, :album, :title, :album_artist, :genre, :track, :disc, :year].each { |s| info[s] ||= '' }
    info[:cover] ||= nil

    TagLib::MPEG::File.open(path) do |f|
      f.strip

      tag = f.id3v2_tag(true)

      # Basic infos
      tag.artist = info[:artist]
      tag.album = info[:album]
      tag.title = info[:title]
      tag.genre = info[:genre]

      # Album artist
      tag.remove_frames('TPE2')
      tag.add_frame(get_text_frame('TPE2', info[:album_artist]))

      # Sorting fields
      tag.remove_frames('TSOT')
      tag.add_frame(get_text_frame('TSOT', PinYin.sentence(tag.title)))

      tag.remove_frames('TSOA')
      tag.add_frame(get_text_frame('TSOA', PinYin.sentence(tag.album)))

      tag.remove_frames('TSOP')
      tag.add_frame(get_text_frame('TSOP', PinYin.sentence(tag.artist)))

      tag.remove_frames('TSO2')
      tag.add_frame(get_text_frame('TSO2', PinYin.sentence(info[:album_artist])))

      tag.remove_frames('TRCK')
      tag.add_frame(get_text_frame('TRCK', info[:track]))

      tag.remove_frames('TPOS')
      tag.add_frame(get_text_frame('TPOS', info[:disc]))

      tag.remove_frames('TDRC')
      tag.add_frame(get_text_frame('TDRC', info[:year]))

      if info[:cover]
        # Album cover
        apic = TagLib::ID3v2::AttachedPictureFrame.new
        apic.mime_type = 'image/png'
        apic.description = 'Cover'
        apic.type = TagLib::ID3v2::AttachedPictureFrame::FrontCover
        apic.picture = File.read(info[:cover])
        tag.add_frame(apic)
      end

      # Save
      f.save
    end
  end

  private
    def self.get_text_frame(frame_id, text)
      t = TagLib::ID3v2::TextIdentificationFrame.new(frame_id, TagLib::String::UTF8)
      t.text = text.to_s
      t
    end
end