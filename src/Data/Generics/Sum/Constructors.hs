{-# LANGUAGE AllowAmbiguousTypes    #-}
{-# LANGUAGE DataKinds              #-}
{-# LANGUAGE FlexibleInstances      #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE KindSignatures         #-}
{-# LANGUAGE MultiParamTypeClasses  #-}
{-# LANGUAGE ScopedTypeVariables    #-}
{-# LANGUAGE TypeApplications       #-}
{-# LANGUAGE TypeFamilies           #-}
{-# LANGUAGE TypeOperators          #-}
{-# LANGUAGE UndecidableInstances   #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  Data.Generics.Sum.Constructors
-- Copyright   :  (C) 2017 Csongor Kiss
-- License     :  BSD3
-- Maintainer  :  Csongor Kiss <kiss.csongor.kiss@gmail.com>
-- Stability   :  experimental
-- Portability :  non-portable
--
-- Derive constructor-name-based prisms generically.
--
-----------------------------------------------------------------------------

module Data.Generics.Sum.Constructors
  ( -- *Prisms

    --  $example
    AsConstructor (..)
  ) where

import Data.Generics.Internal.Families
import Data.Generics.Internal.Lens
import Data.Generics.Sum.Internal.Constructors

import Data.Kind    (Constraint, Type)
import GHC.Generics (Generic (Rep))
import GHC.TypeLits (Symbol, TypeError, ErrorMessage (..))

--  $example
--  @
--    module Example where
--
--    import Data.Generics.Sum
--    import GHC.Generics
--
--    data Animal
--      = Dog Dog
--      | Cat Name Age
--      | Duck Age
--      deriving (Generic, Show)
--
--    data Dog = MkDog
--      { name :: Name
--      , age  :: Age
--      }
--      deriving (Generic, Show)
--
--    type Name = String
--    type Age  = Int
--
--    dog, cat, duck :: Animal
--
--    dog = Dog (MkDog "Shep" 3)
--    cat = Cat "Mog" 5
--    duck = Duck 2
--  @

-- |Sums that have a constructor with a given name.
class AsConstructor (ctor :: Symbol) a s | s ctor -> a where
  -- |A prism that projects a named constructor from a sum. Compatible with the
  --  lens package's 'Control.Lens.Prism' type.
  --
  --  >>> dog ^? _Ctor @"Dog"
  --  Just (MkDog {name = "Shep", age = 3})
  --
  --  >>> dog ^? _Ctor @"Cat"
  --  Nothing
  --
  --  >>> cat ^? _Ctor @"Cat"
  --  Just ("Mog", 5)
  --
  --  >>> _Ctor @"Cat" # ("Garfield", 6) :: Animal
  --  Cat ("Garfield", 6)
  _Ctor :: Prism' s a

instance
  ( Generic s
  , ErrorUnless ctor s (HasCtorP ctor (Rep s))
  , GAsConstructor ctor (Rep s) a
  ) => AsConstructor ctor a s where

  _Ctor = repIso . _GCtor @ctor

type family ErrorUnless (ctor :: Symbol) (s :: Type) (contains :: Bool) :: Constraint where
  ErrorUnless ctor s 'False
    = TypeError
        (     'Text "The type "
        ':<>: 'ShowType s
        ':<>: 'Text " does not contain a constructor named "
        ':<>: 'ShowType ctor
        )

  ErrorUnless _ _ 'True
    = ()
