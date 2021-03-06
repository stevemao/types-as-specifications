{-# LANGUAGE DataKinds            #-}
{-# LANGUAGE FlexibleInstances    #-}
{-# LANGUAGE GADTs                #-}
{-# LANGUAGE PolyKinds            #-}
{-# LANGUAGE TypeFamilies         #-}
{-# LANGUAGE TypeOperators        #-}
{-# LANGUAGE UndecidableInstances #-}

module Typelevel.Solutions.Lists where

import Data.Kind (Type, Constraint)
import Data.Type.Bool
import Data.Type.Equality ((:~:) (..))
import Prelude hiding (Bool)
import Typelevel.Solutions.Basics

----------------------------------------
-- Exercise 1
--
--   Implement the Append type family for length indexed lists
----------------------------------------

data NList (n :: Nat) (a :: *) where
  NNil :: NList 'Zero a
  NCons :: a -> NList n a -> NList ('Succ n) a

nappend :: NList n a -> NList m a -> NList (Add n m) a
nappend NNil m = case nappendLemma1 NNil m of Refl -> m
nappend n@(NCons a rest) m =
  case nappendLemma2 n m of
    Refl -> NCons a (nappend rest m)

nappendLemma1 :: NList 'Zero a -> NList m a -> NList (Add 'Zero m) a :~: NList m a
nappendLemma1 NNil m = Refl

nappendLemma2
  :: NList ('Succ n) a
  -> NList m a
  -> NList ('Succ (Add n m)) a :~: NList (Add n ('Succ m)) a
nappendLemma2 (NCons _ rest) m =
  case rest of
    NNil -> case nappendLemma1 rest m of Refl -> Refl
    NCons _ _ -> case nappendLemma2 rest m of Refl -> Refl

----------------------------------------
-- Exercise 2
--
--   Implement the Append type family for type-level lists
----------------------------------------

type family Append (xs :: [Type]) (ys :: [Type]) :: [Type] where
  Append '[] ys = ys
  Append xs '[] = xs
  Append (x ': xs) ys = x ': Append xs ys

type family Map (f :: k -> j) (xs :: [k]) :: [j] where
  Map f '[] = '[]
  Map f (x ': xs) = f x ': Map f xs

type family Filter (p :: k -> Bool) (xs :: [k]) :: [k] where
  Filter p '[] = '[]
  Filter p (x ': xs) =
    IfThenElse (p x)
      (x ': Filter p xs)
      (Filter p xs)

-- Note how this won't compile, because '<=?' expects to be fully saturated
--
-- filterTest1 = Refl :: Filter (<=? 5) '[3,5,7] :~: '[5]

--------------------------------------------------------------------------------
-- Heterogenous Lists ("n-ary tuples"):
--
--   A datatype ranging over list values that can differ in the type of their
--   elements.
--------------------------------------------------------------------------------

data HList (a :: [*]) where
  HNil :: HList '[]
  HCons :: x -> HList xs -> HList (x ': xs)

----------------------------------------
-- Exercise 3
--
--   Implement a 'Show' instance for the HList datatype
----------------------------------------
instance Show (HList '[]) where
  show HNil = "[]"

instance (Show x, Show (HList xs)) => Show (HList (x ': xs)) where
  show (HCons x xs) = show x ++ " .:. " ++ show (xs)

----------------------------------------
-- Exercise 4
--
--   Type-level head & tail of heterogenous list
--
-- Note: We don't need tests for these. Why not?
----------------------------------------

hhead :: HList (x ': xs) -> x
hhead (HCons x xs) = x

htail :: HList (x ': xs) -> HList xs
htail (HCons x xs) = xs

----------------------------------------

type family All (c :: k -> Constraint) (xs :: [k]) :: Constraint where
  All _ '[] = ()
  All c (x ': xs) = (c x, All c xs)

----------------------------------------
-- Exercise 5
--
--   Re-implement the `Show` instance for HLists making use of the 'All' type
--   family.
----------------------------------------

instance {-# OVERLAPPABLE #-} All Show xs => Show (HList xs) where
  show HNil = "[]"
  show (HCons x xs) = show x ++ " .:. " ++ show xs

----------------------------------------
-- Live Programming
----------------------------------------

----------------------------------------
--   Type-level concatenation of Heterogenous lists
--
--     - Write the instance
--     - Look at the type error & discuss
--     - Discuss the :~: in Data.Type.Equality
--     - Write the proofs (lemmas)
--     - Fix the instance!
----------------------------------------

happendLemma1 :: HList xs -> HList '[] -> HList (Append xs '[]) :~: HList xs
happendLemma1 _ _ = Refl

happendLemma2 :: HList (x ': xs) -> HList ys -> HList (x ': Append xs ys) :~: HList (Append (x ': xs) ys)
happendLemma2 h1@(HCons x xs) HNil         = happendLemma1 h1 HNil
happendLemma2 h1@(HCons x xs) (HCons y ys) = Refl -- here we trivially assert equality: "trust me, GHC"

happend :: HList xs -> HList ys -> HList (Append xs ys)
happend HNil ys         = ys
happend xs HNil         = xs
happend h1@(HCons x xs) h2 =
  case happendLemma2 h1 h2 of
    Refl -> HCons x (happend xs h2)

----------------------------------------
-- Discussion Question:
--
--   Why can't we write a function `hconcat` over heterogenous lists?
--     hconcat :: HList xss -> HList xs
----------------------------------------
