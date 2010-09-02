import qualified Data.ByteString.Lazy.Char8 as B
import Text.Regex.PCRE
import Data.Algorithm.Diff
-- import Control.Parallel.Strategies
-- import Control.DeepSeq
-- instance NFData B.ByteString where
--   rnf bytestr = B.length bytestr `seq` ()

deltaSize a b = sum $ map (B.length . snd) $ filter ((/= B) . fst) $ getDiff (B.words a) (B.words b)

revisionPageRevisionFormat = B.pack "<text[^>]*>([^<]*)</text>.*<page> <title>([^<]+)</title> <id>([0-9]+)</id>.*<revision> <id>([0-9]+)</id> <timestamp>([-:TZ0-9]+)</timestamp> <contributor> (<ip>([^<]+)</ip>|<username>([^<]+)</username> <id>([0-9]+)</id>).*<text[^>]*>([^<]*)</text>"
revisionSql revId revTime pageId pageTitle thisUser diffSize = B.concat [B.pack "insert or ignore into pages values (",   pageId,   B.pack ", '",   sqliteEscape pageTitle,   B.pack "');\n",
	    	  	  	 	   	    	       	       B.pack "insert into revisions values (", revId, B.pack ", strftime('%s', '", revTime, B.pack "'), ", pageId,
								       	      	      	   	     	    	B.pack ", '", sqliteEscape thisUser, B.pack "', ", B.pack $ show diffSize, B.pack ");\n" ]
sqliteEscape = B.filter (/= '\'')

joinUserData = B.intercalate (B.pack "<")

parsePageRev [oldText, pageTitle, pageId, revId, revTime, _, userIp, userName, userId, revText] = let thisUser = joinUserData [userId, userName, userIp]
	     	       		  	  	 	     	     	       	       		      diffSize = if B.length revText == 0
												      	       	   then B.length oldText
														   else if B.length oldText == 0
														          then B.length revText
															  else deltaSize revText oldText in
	 	     	     	       	  	   	      	       		        	    revisionSql revId revTime pageId pageTitle thisUser diffSize
parseRev _ = error "bad parse of revision"

parse s = if [] == matches then B.pack "-- bad line:" `B.append` s else parsePageRev matches
  where (_,_,_,matches) = (s =~ revisionPageRevisionFormat :: (B.ByteString, B.ByteString, B.ByteString, [B.ByteString]))

main = B.interact (B.concat . map parse . filter (not . B.null) . B.lines)

