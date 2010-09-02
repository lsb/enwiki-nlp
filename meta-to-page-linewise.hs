import qualified Data.ByteString.Lazy.Char8 as B
import qualified Data.List as L
import Char

main = B.interact (B.unlines . linesToLinePairs . pageRevisionPairs . onlyPagesAndRevisions . B.lines . B.unwords . pageRevisionLinewise . filter (not . B.null) . B.lines)

linesToLinePairs pagerevs = zipWith (\a b -> if B.null b then B.empty else ((if B.null a then B.pack "<text></text>" else a) `B.append` b)) pagerevs (tail pagerevs)
pageRevisionPairs = snd . L.mapAccumL (\page line -> if (B.pack "<page") `B.isPrefixOf` line then (line, B.empty) else (page, page `B.append` line)) B.empty
isPageOrRevision s = (B.pack "<page") `B.isPrefixOf` s || (B.pack "<revision") `B.isPrefixOf` s
onlyPagesAndRevisions = filter isPageOrRevision
pageRevisionLinewise = map (\s -> let stripped = B.dropWhile isSpace s in
		       	       	    if isPageOrRevision stripped
				       then '\n' `B.cons` stripped
				       else if B.null stripped || '<' == B.head stripped
				       	      then (if (B.pack "<text xml:space=\"preserve\" />") == stripped then B.pack "<text xml></text>" else stripped)
					      else s)
