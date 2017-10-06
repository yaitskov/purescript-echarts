module ECharts.Monad where

import Prelude

import Control.Alt (class Alt)
import Control.Alternative (class Alternative)
import Control.MonadPlus (class MonadPlus)
import Control.MonadZero (class MonadZero)
import Control.Monad.Cont.Class (class MonadCont)
import Control.Monad.Eff.Class (class MonadEff)
import Control.Monad.Aff.Class (class MonadAff)
import Control.Monad.Error.Class (class MonadError, class MonadThrow)
import Control.Monad.Reader.Class (class MonadAsk, class MonadReader)
import Control.Monad.State.Class (class MonadState)
import Control.Monad.Eff (kind Effect)
import Control.Monad.Rec.Class (class MonadRec)
import Control.Monad.Writer.Trans (WriterT(..), execWriterT)
import Control.Monad.Writer.Class (class MonadTell, class MonadWriter, tell)
import Control.Plus (class Plus, empty)
import Data.Array as Arr
import Data.Foldable as F
import Data.Identity (Identity)
import Data.Foreign (Foreign, toForeign)
import Data.Maybe (Maybe(..), maybe)
import Data.Newtype (class Newtype, unwrap)
import Data.Tuple (Tuple(..), uncurry, snd, lookup)
import ECharts.Internal (unsafeSetField, emptyObject)
import ECharts.Types as ET

type KeyVal = Tuple String Foreign
type Pairs = Array KeyVal

newtype CommandsT (i ∷ # Effect) m a = CommandsT (WriterT Pairs m a)

type DSL i m = CommandsT i m Unit
type DSL' i = CommandsT i Identity Unit

derive instance newtypeCommandsT
  ∷ Newtype (CommandsT i m a) _
derive newtype instance functorDSL
  ∷ Functor m ⇒ Functor (CommandsT i m)
derive newtype instance applyDSL
  ∷ Apply m ⇒ Apply (CommandsT i m)
derive newtype instance applicativeDSL
  ∷ Applicative m ⇒ Applicative (CommandsT i m)
derive newtype instance bindDSL
  ∷ Bind m ⇒ Bind (CommandsT i m)
derive newtype instance monadDSL
  ∷ Monad m ⇒ Monad (CommandsT i m)
derive newtype instance monadTellCommandsT
  ∷ Monad m ⇒ MonadTell (Array (Tuple String Foreign)) (CommandsT i m)
derive newtype instance monadWriterCommandsT
  ∷ Monad m ⇒ MonadWriter (Array (Tuple String Foreign)) (CommandsT i m)
derive newtype instance plusCommandsT
  ∷ Plus m ⇒ Plus (CommandsT i m)
derive newtype instance altCommandsT
  ∷ Alt m ⇒ Alt (CommandsT i m)
derive newtype instance alternativeCommandsT
  ∷ Alternative m ⇒ Alternative (CommandsT i m)
derive newtype instance monadRecCommandsT
  ∷ MonadRec m ⇒ MonadRec (CommandsT i m)
derive newtype instance monadZeroCommandsT
  ∷ MonadZero m ⇒ MonadZero (CommandsT i m)
derive newtype instance monadPlusCommandsT
  ∷ MonadPlus m ⇒ MonadPlus (CommandsT i m)
derive newtype instance monadAffCommandsT
  ∷ MonadAff e m ⇒ MonadAff e (CommandsT i m)
derive newtype instance monadEffCommandsT
  ∷ MonadEff e m ⇒ MonadEff e (CommandsT i m)
derive newtype instance monadContCommandsT
  ∷ MonadCont m ⇒ MonadCont (CommandsT i m)
derive newtype instance monadThrowCommandsT
  ∷ MonadThrow e m ⇒ MonadThrow e (CommandsT i m)
derive newtype instance monadErrorCommandsT
  ∷ MonadError e m ⇒ MonadError e (CommandsT i m)
derive newtype instance monadAskCommandsT
  ∷ MonadAsk r m ⇒ MonadAsk r (CommandsT i m)
derive newtype instance monadReaderCommandsT
  ∷ MonadReader r m ⇒ MonadReader r (CommandsT i m)
derive newtype instance monadStateCommandsT
  ∷ MonadState s m ⇒ MonadState s (CommandsT i m)

lift ∷ ∀ m i a. Monad m ⇒ m a → CommandsT i m a
lift a = CommandsT $ WriterT do
  x ← a
  pure $ Tuple x []

set ∷ ∀ m. MonadTell Pairs m ⇒ String → Foreign → m Unit
set k v = tell $ Arr.singleton $ Tuple k v

get
  ∷ ∀ i m f a ii
  . Monad m
  ⇒ Alternative f
  ⇒ String
  → CommandsT i m a
  → CommandsT ii m (f Foreign)
get k cs =
  lift $ unwrap cs # execWriterT >>> map (maybe empty pure <<< lookup k)

lastWithKeys
  ∷ ∀ i f m w a ii
  . F.Foldable f
  ⇒ Monad m
  ⇒ Alternative w
  ⇒ f String
  → CommandsT i m a
  → CommandsT ii m (w Foreign)
lastWithKeys ks cs =
  lift $ unwrap cs # execWriterT >>> map (maybe empty pure <<< F.foldl (lookup' ks) Nothing)
  where
  lookup' ∷ f String → Maybe Foreign → Tuple String Foreign → Maybe Foreign
  lookup' ks' Nothing (Tuple kk f) | F.elem kk ks' = Just f
  lookup' _ a _ = a

applyOnePair ∷ Tuple String Foreign → Foreign → Foreign
applyOnePair opt obj = uncurry (unsafeSetField obj) opt

interpretT ∷ ∀ i m a. Functor m ⇒ CommandsT i m a → m ET.Option
interpretT cs =
  map ET.Option $ unwrap cs # execWriterT >>> map (F.foldr applyOnePair $ emptyObject unit)

interpret ∷ ∀ i. DSL' i → ET.Option
interpret = unwrap <<< interpretT

buildObj ∷ ∀ i m a ii. Monad m ⇒ CommandsT i m a → CommandsT ii m Foreign
buildObj cs = lift $ unwrap cs # execWriterT >>> map (F.foldr applyOnePair $ emptyObject unit)

buildSeries ∷ ∀ i m a ii. Monad m ⇒ CommandsT i m a → CommandsT ii m Foreign
buildSeries cs =
  lift $ unwrap cs # execWriterT >>> map (toForeign <<< typify)
  where
  typify = map \(Tuple ty f) → unsafeSetField f "type" $ toForeign ty

buildArr ∷ ∀ i m a ii. Monad m ⇒ CommandsT i m a → CommandsT ii m Foreign
buildArr cs =
  lift $ unwrap cs # execWriterT >>> map (toForeign <<< map snd)
