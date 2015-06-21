defmodule Kademlia.Protobuf do
  use Protobuf, from: Path.expand("./kademlia.proto", __DIR__)

  @type pb_node :: %Kademlia.Protobuf.PBNode{}
  @type pb_header :: %Kademlia.Protobuf.PBHeader{}
  @type pb_ping_request :: %Kademlia.Protobuf.PBPingRequest{}
  @type pb_ping_response :: %Kademlia.Protobuf.PBPingResponse{}
  @type pb_find_node_request :: %Kademlia.Protobuf.PBFindNodeRequest{}
  @type pb_find_node_response :: %Kademlia.Protobuf.PBFindNodeResponse{}
  @type pb_find_value_request :: %Kademlia.Protobuf.PBFindValueRequest{}
  @type pb_find_value_response :: %Kademlia.Protobuf.PBFindValueResponse{}
  @type pb_store_value_request :: %Kademlia.Protobuf.PBStoreValueRequest{}
  @type pb_store_value_response :: %Kademlia.Protobuf.PBStoreValueResponse{}

end
