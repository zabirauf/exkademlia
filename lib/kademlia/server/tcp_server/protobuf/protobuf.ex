defmodule Kademlia.Server.TcpServer.Protobuf do
  use Protobuf, from: Path.expand("./kademlia.proto", __DIR__)

  alias Kademlia.Server.TcpServer.Protobuf, as: PB

  @type pb_node :: %PB.PBNode{}
  @type pb_header :: %PB.PBHeader{}
  @type pb_ping_request :: %PB.PBPingRequest{}
  @type pb_ping_response :: %PB.PBPingResponse{}
  @type pb_find_node_request :: %PB.PBFindNodeRequest{}
  @type pb_find_node_response :: %PB.PBFindNodeResponse{}
  @type pb_find_value_request :: %PB.PBFindValueRequest{}
  @type pb_find_value_response :: %PB.PBFindValueResponse{}
  @type pb_store_value_request :: %PB.PBStoreValueRequest{}
  @type pb_store_value_response :: %PB.PBStoreValueResponse{}

end
