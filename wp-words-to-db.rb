require 'cgi'
def w
  IO.popen('bzip2 -cd enwiki-latest-pages-articles.xml.bz2') {|wpfile|
    wpfile.each('</page>') {|page|
      rawxml = page[/<page.+<\/page>$/m]
      next unless rawxml
      yield rawxml
    }
  }
end
def unmarkup(wtext)
  CGI.unescapeHTML(wtext).
      gsub(/<br ?\/?>/,"\n").gsub(/<!--.+?->/m,"").
      gsub(/<(s|sup|sub|code|ref|references|includeonly|noinclude)[^<]+<\/\1>/m) {|tag| ''}.
      gsub(/'{2,}/) {|emphasis| ''}.
      gsub(/#REDIRECT \[\[.+?\]\]/) {|redirection|  '' }.
      gsub(/~~~~|----/,'').tr('=','').
      gsub(/\[\[[-a-z]+:[^\]]+\]\]/) {|category| ''}.
      gsub(/\[\[(?:Category|Template):[^\]]+\]\]/) {|cat_templ|  ''}.
      gsub(/\{[^\{\}]*\}/) {|metadata| ''}.gsub(/\{[^\{\}]*\}/) {|metadata| ''}.
      gsub(/\{[^\{\}]*\}/) {|metadata| ''}.gsub(/\{[^\{\}]*\}/) {|metadata| ''}.
      gsub(/\{[^\{\}]*\}/) {|metadata| ''}.gsub(/\{[^\{\}]*\}/) {|metadata| ''}.
      gsub('{}','').
      gsub(/\[\[([^\]|]+)\]\]/) {|ln| $1 }.
      gsub(/\[\[[^\]\[]+\|([^\]\[]+)\]\]/) {|ln| $1 }.
      gsub(/\[\[[^\]\[]+\|([^\]\[]+)\]\]/) {|ln| $1 }.
      gsub(/\[\[[^\]\[]+\|([^\]\[]+)\]\]/) {|ln| $1 }.
      gsub(/<[^>]+>/) {|tag| ''}.strip.gsub(/\n+/,"\n")
end
def unmarkedup
  text = /<text.+<\/text>/m
  w {|wpage|
    pagetext = wpage[text]
    next if pagetext.nil?
    unmarkedup = unmarkup(pagetext)
    yield unmarkedup unless unmarkedup.empty?
  }
end
def make_sql
  word_id_autoincrement = 0
  corpus_id_autoincrement = 0
  word_id = Hash.new {|h,k| h[k] = word_id_autoincrement += 1 }
  File.read('top_1000_words.txt').scan(/\w+/, &word_id.method(:[])) if File.exist?('top_1000_words.txt')
  article_id = 0
  puts "begin;"
  unmarkedup {|text|
    article_id += 1
    text.downcase.scan(/[a-z]+/) {|word|
      w = word_id[word]
      corpus_id_autoincrement += 1
      print "insert into corpus_words values (#{corpus_id_autoincrement},#{article_id},#{w});\n"
      (print 'commit;begin;'; STDERR.print ".") if corpus_id_autoincrement.%(10_000_000).zero?
    }
  }
  puts "commit;"
  STDERR.puts `wget -q --output-document=- lsb.nfshost.com/tellme.php`
  puts "begin;"  
  word_id.sort_by {|k,v| v}.each {|k,v| print "insert into words values (#{v},'#{k}');\n" }
  puts "commit;"
end

