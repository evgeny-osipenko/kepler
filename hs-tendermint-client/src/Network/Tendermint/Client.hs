module Network.Tendermint.Client where

import           Control.Monad.Reader                         (ReaderT,
                                                               runReaderT)
import           Data.Aeson                                   (FromJSON (..),
                                                               ToJSON (..),
                                                               genericParseJSON,
                                                               genericToJSON)
import qualified Data.Aeson                                   as Aeson
import           Data.Aeson.Casing                            (aesonDrop,
                                                               pascalCase,
                                                               snakeCase)
import           Data.ByteArray.HexString                     (HexString)
import           Data.Int                                     (Int64)
import           Data.Text                                    (Text)
import           Data.Word                                    (Word32)
import           GHC.Generics                                 (Generic)
import qualified Network.ABCI.Types.Messages.FieldTypes       as FieldTypes
import qualified Network.ABCI.Types.Messages.Response         as Response
import qualified Network.HTTP.Simple                          as HTTP
import qualified Network.Tendermint.Client.Internal.RPCClient as RPC

type TendermintM a = ReaderT RPC.Config IO a

runTendermintM :: RPC.Config -> TendermintM a -> IO a
runTendermintM = flip runReaderT

defaultConfig :: RPC.Config
defaultConfig = RPC.Config
  $ HTTP.setRequestHost "localhost"
  $ HTTP.setRequestPort 26657
  $ HTTP.defaultRequest

-- | invokes [/abci_info](https://tendermint.com/rpc/#abciinfo) rpc call
-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/abci.go#L100
abciInfo :: TendermintM ResultABCIInfo
abciInfo = RPC.remote (RPC.MethodName "abci_info") ()
-- | invokes [/health](https://tendermint.com/rpc/#health) rpc call
-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/health.go#L35
health :: TendermintM ResultHealth
health = RPC.remote (RPC.MethodName "health") ()
-- | invokes [/abci_query](https://tendermint.com/rpc/#abciquery) rpc call
-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/abci.go#L56
abciQuery :: RequestABCIQuery -> TendermintM ResultABCIQuery
abciQuery = RPC.remote (RPC.MethodName "abci_query")
-- | invokes [/block](https://tendermint.com/rpc/#block) rpc call
-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/blocks.go#L72
block :: RequestBlock -> TendermintM ResultBlock
block = RPC.remote (RPC.MethodName "block")
-- | invokes [/tx](https://tendermint.com/rpc/#tx) rpc call
-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/tx.go#L81
tx :: RequestTx -> TendermintM ResultTx
tx = RPC.remote (RPC.MethodName "tx")
-- | invokes [/broadcast_tx_async](https://tendermint.com/rpc/#broadcasttxasync) rpc call
-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/mempool.go#L75
broadcastTxAsync :: RequestBroadcastTxAsync -> TendermintM ResultBroadcastTx
broadcastTxAsync = RPC.remote (RPC.MethodName "broadcast_tx_async")
-- | invokes [/broadcast_tx_sync](https://tendermint.com/rpc/#broadcasttxsync) rpc call
-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/mempool.go#L136
broadcastTxSync :: RequestBroadcastTxSync -> TendermintM ResultBroadcastTx
broadcastTxSync = RPC.remote (RPC.MethodName "broadcast_tx_sync")
-- | invokes [/broadcast_tx_commit](https://tendermint.com/rpc/#broadcasttxcommit) rpc call
-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/mempool.go#L215
broadcastTxCommit :: RequestBroadcastTxCommit -> TendermintM ResultBroadcastTxCommit
broadcastTxCommit = RPC.remote (RPC.MethodName "broadcast_tx_commit")



defaultRPCOptions :: String -> Aeson.Options
defaultRPCOptions prefix = aesonDrop (length prefix) snakeCase



-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/abci.go#L56
data RequestABCIQuery = RequestABCIQuery
  { requestABCIQueryPath   :: Text
  , requestABCIQueryData   :: HexString
  , requestABCIQueryHeight :: Int64
  , requestABCIQueryProve  :: Bool
  } deriving (Eq, Show, Generic)
instance ToJSON RequestABCIQuery where
  toJSON = genericToJSON $ defaultRPCOptions "requestABCIQuery"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/blocks.go#L72
data RequestBlock = RequestBlock
  { requestBlockHeightPtr :: Maybe Int64
  } deriving (Eq, Show, Generic)
instance ToJSON RequestBlock where
  toJSON = genericToJSON $ defaultRPCOptions "requestBlock"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/tx.go#L81
data RequestTx = RequestTx
  { requestTxHash  :: HexString
  , requestTxProve :: Bool
  } deriving (Eq, Show, Generic)
instance ToJSON RequestTx where
  toJSON = genericToJSON $ defaultRPCOptions "requestTx"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/mempool.go#L75
data RequestBroadcastTxAsync = RequestBroadcastTxAsync
  { requestBroadcastTxAsyncTx :: Tx
  } deriving (Eq, Show, Generic)
instance ToJSON RequestBroadcastTxAsync where
  toJSON = genericToJSON $ defaultRPCOptions "requestBroadcastTxAsync"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/mempool.go#L136
data RequestBroadcastTxSync = RequestBroadcastTxSync
  { requestBroadcastTxSyncTx :: Tx
  } deriving (Eq, Show, Generic)
instance ToJSON RequestBroadcastTxSync where
  toJSON = genericToJSON $ defaultRPCOptions "requestBroadcastTxSync"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/mempool.go#L215
data RequestBroadcastTxCommit = RequestBroadcastTxCommit
  { requestBroadcastTxCommitTx :: Tx
  } deriving (Eq, Show, Generic)
instance ToJSON RequestBroadcastTxCommit where
  toJSON = genericToJSON $ defaultRPCOptions "requestBroadcastTxCommit"


-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/types/responses.go#L208
type ResultHealth = ()


-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/types/responses.go#L188
data ResultABCIInfo = ResultABCIInfo
  { resultABCIInfoResponse :: Response.Info
  } deriving (Eq, Show, Generic)
instance FromJSON ResultABCIInfo where
  parseJSON = genericParseJSON $ defaultRPCOptions "resultABCIInfo"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/types/responses.go#L193
data ResultABCIQuery = ResultABCIQuery
  { resultABCIQueryResponse :: Response.Query
  } deriving (Eq, Show, Generic)
instance FromJSON ResultABCIQuery where
  parseJSON = genericParseJSON $ defaultRPCOptions "resultABCIQuery"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/types/responses.go#L28
data ResultBlock = ResultBlock
  { resultBlockBlockMeta :: BlockMeta
  , resultBlockBlock     :: Block
  } deriving (Eq, Show, Generic)
instance FromJSON ResultBlock where
  parseJSON = genericParseJSON $ defaultRPCOptions "resultBlock"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/types/responses.go#L164
data ResultTx = ResultTx
  { resultTxHash     :: HexString
  , resultTxHeight   :: Int64
  , resultTxIndex    :: Word32
  , resultTxTxResult :: Response.DeliverTx
  , resultTxTx       :: Tx
  , resultTxProof    :: TxProof
  } deriving (Eq, Show, Generic)
instance FromJSON ResultTx where
  parseJSON = genericParseJSON $ defaultRPCOptions "resultTx"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/types/responses.go#L147
data ResultBroadcastTx = ResultBroadcastTx
  { resultBroadcastTxCode :: Word32
  , resultBroadcastTxData :: HexString
  , resultBroadcastTxLog  :: Text
  , resultBroadcastTxHash :: HexString
  } deriving (Eq, Show, Generic)
instance FromJSON ResultBroadcastTx where
  parseJSON = genericParseJSON $ defaultRPCOptions "resultBroadcastTx"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/rpc/core/types/responses.go#L156
data ResultBroadcastTxCommit = ResultBroadcastTxCommit
  { resultBroadcastTxCommitCheckTx   :: Response.CheckTx
  , resultBroadcastTxCommitDeliverTx :: Response.DeliverTx
  , resultBroadcastTxCommitHash      :: HexString
  , resultBroadcastTxCommitHeight    :: Int64
  } deriving (Eq, Show, Generic)
instance FromJSON ResultBroadcastTxCommit where
  parseJSON = genericParseJSON $ defaultRPCOptions "resultBroadcastTxCommit"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/types/tx.go#L85
data TxProof = TxProof
  { txProofRootHash :: HexString
  , txProofData     :: Tx
  , txProofProof    :: SimpleProof
  } deriving (Eq, Show, Generic)
instance FromJSON TxProof where
  parseJSON = genericParseJSON $ aesonDrop (length ("txProof" :: String)) pascalCase

-- https://github.com/tendermint/tendermint/blob/v0.32.2/crypto/merkle/simple_proof.go#L18
data SimpleProof = SimpleProof
  { simpleProofTotal    :: Int
  , simpleProofIndex    :: Int
  , simpleProofLeafHash :: HexString
  , simpleProofAunts    :: [HexString]
  } deriving (Eq, Show, Generic)
instance FromJSON SimpleProof where
  parseJSON = genericParseJSON $ defaultRPCOptions "simpleProof"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/types/block_meta.go#L4
data BlockMeta = BlockMeta
  { blockMetaBlockId :: FieldTypes.BlockID
  , blockMetaHeader  :: FieldTypes.Header
  } deriving (Eq, Show, Generic)
instance FromJSON BlockMeta where
  parseJSON = genericParseJSON $ defaultRPCOptions "blockMeta"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/types/block.go#L36
data Block = Block
  { blockHeader     :: FieldTypes.Header
  , blockData       :: Data
  , blockEvidence   :: EvidenceData
  , blockLastCommit :: Maybe Commit
  } deriving (Eq, Show, Generic)
instance FromJSON Block where
  parseJSON = genericParseJSON $ defaultRPCOptions "block"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/types/block.go#L774
data Data = Data
  { dataTxs :: [Tx]
  } deriving (Eq, Show, Generic)
instance FromJSON Data where
  parseJSON = genericParseJSON $ defaultRPCOptions "data"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/types/block.go#L819~
data EvidenceData = EvidenceData
  { evidenceDataEvidence :: EvidenceList
  } deriving (Eq, Show, Generic)
instance FromJSON EvidenceData where
  parseJSON = genericParseJSON $ defaultRPCOptions "evidenceData"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/types/evidence.go#L278
type EvidenceList = [FieldTypes.Evidence]

-- https://github.com/tendermint/tendermint/blob/v0.32.2/types/block.go#L488
data Commit = Commit
  { commitBlockId    :: FieldTypes.BlockID
  , commitPrecommits :: [Vote]
  } deriving (Eq, Show, Generic)
instance FromJSON Commit where
  parseJSON = genericParseJSON $ defaultRPCOptions "commit"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/types/vote.go#L51
data Vote = Vote
  { voteType             :: SignedMsgType
  , voteHeight           :: Int64
  , voteRound            :: Int
  , voteBlockId          :: FieldTypes.BlockID
  , voteTimestamp        :: FieldTypes.Timestamp
  , voteValidatorAddress :: HexString
  , voteValidatorIndex   :: Int
  , voteSignature        :: HexString
  } deriving (Eq, Show, Generic)
instance FromJSON Vote where
  parseJSON = genericParseJSON $ defaultRPCOptions "vote"

-- https://github.com/tendermint/tendermint/blob/v0.32.2/types/tx.go#L19
type Tx = HexString

-- https://github.com/tendermint/tendermint/blob/v0.32.2/types/signed_msg_type.go#L4
data SignedMsgType
  = PrevoteType
  | PrecommitType
  | ProposalType
  deriving (Eq, Show, Generic)

instance FromJSON SignedMsgType where
  parseJSON = Aeson.withScientific "SignedMsgType" $ \n -> case n of
    1  -> pure PrevoteType
    2  -> pure PrecommitType
    32 -> pure ProposalType
    _  -> fail $ "invalid SignedMsg code: " <> show n


