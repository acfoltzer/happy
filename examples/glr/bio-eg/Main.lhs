> module Main where
> import System(getArgs)
> import Maybe(fromJust)
> import Bio
> import Data.FiniteMap
> import Control.Monad.State

>#include "DV_lhs"

> main 
>  = do
>	[s] <- getArgs
>	case doParse $ map (:[]) $ lexer s of 
>	  ParseOK r f -> do 
>			    let f_ = filter_noise f
>			    putStrLn $ "Ok " ++ show r ++ "\n" 
>						++ unlines (map show f_)
>			    --writeFile "full" (unlines $ map show f)
>			    toDV (trim_graph f_ r)
>	  ParseEOF f  -> do 
>			    let f_ = filter_noise f
>			    putStrLn $ "Premature end of input:\n" 
>						++ unlines (map show f_)
>			    toDV f_
>			    --writeFile "full" (unlines $ map show f)
>	  ParseError ts f -> do 
>			    let f_ = filter_noise f
>			    putStrLn $ "Error: " ++ show ts
>			    toDV f_ 
>			    --writeFile "full" (unlines $ map show f)

> forest_lookup f i 
>  = case lookup i f of
>	Just (FNode _ _ s bs) -> (s,bs)

---
remove intergenic things, to make graph small enough for drawing
 -- (prefer to do this with filtering in parser...)

> filter_noise f
>  = [ (i, FNode s_i e_i l $ map filter_branch bs) 
>    | (i, FNode s_i e_i l bs) <- f, not_igs i ]
>    where
>	igs = listToFM [ (i,False) | (i, FNode _ _ G_Intergenic_noise _) <- f ]
>	not_igs = lookupWithDefaultFM igs True 
>	filter_branch (Branch s ns) = Branch s [ n | n <- ns, not_igs n ]

> trim_graph f r
>  = [ (i,n) | (i,n) <- f, lookupWithDefaultFM wanted False i ]
>    where
>	table = listToFM f
>	wanted = snd $ runState (follow r) emptyFM
>	follow :: Int -> State (FiniteMap Int Bool) ()
>	follow i = do
>	             visited <- get 
>	             if lookupWithDefaultFM visited False i
>	               then return ()
>	               else do
>	                      case lookupFM table i of 
>	                        Nothing 
>	                          -> error $ "bad node: " ++ show i
>	                        Just n@(FNode _ _ _ bs) 
>	                          -> do
>	                                modify (\s -> addToFM s i True)
>	                                mapM_ follow $ concatMap b_nodes bs

