open Import
open Types

type _ t =
  | WorkspaceApplyEdit :
      ApplyWorkspaceEditParams.t
      -> ApplyWorkspaceEditResponse.t t
  | WorkspaceFolders : WorkspaceFolder.t list t
  | WorkspaceConfiguration : ConfigurationParams.t -> Json.t list t
  | ClientRegisterCapability : RegistrationParams.t -> unit t
  | ClientUnregisterCapability : UnregistrationParams.t -> unit t
  | ShowMessageRequest :
      ShowMessageRequestParams.t
      -> MessageActionItem.t option t
  | UnknownRequest : string * Json.t option -> unit t

type packed = E : 'r t -> packed

let method_ (type a) (t : a t) =
  match t with
  | WorkspaceConfiguration _ -> "workspace/configuration"
  | WorkspaceFolders -> "workspace/workspaceFolders"
  | WorkspaceApplyEdit _ -> "workspace/applyEdit"
  | ClientRegisterCapability _ -> "client/registerCapability"
  | ClientUnregisterCapability _ -> "client/unregisterCapability"
  | ShowMessageRequest _ -> "window/showMessageRequest"
  | UnknownRequest _ -> assert false

let params (type a) (t : a t) =
  match t with
  | WorkspaceApplyEdit params -> ApplyWorkspaceEditParams.yojson_of_t params
  | WorkspaceFolders -> `Null
  | WorkspaceConfiguration params -> ConfigurationParams.yojson_of_t params
  | ClientRegisterCapability params -> RegistrationParams.yojson_of_t params
  | ClientUnregisterCapability params -> UnregistrationParams.yojson_of_t params
  | ShowMessageRequest params -> ShowMessageRequestParams.yojson_of_t params
  | UnknownRequest (_, _) -> assert false

let to_jsonrpc_request t ~id =
  let method_ = method_ t in
  let params = params t in
  Jsonrpc.Request.create ~id ~method_ ~params ()

let of_jsonrpc (r : Jsonrpc.Request.t) : (packed, string) Result.t =
  let open Result.O in
  let parse f = Jsonrpc.Request.params r f in
  match r.method_ with
  | "workspace/configuration" ->
    let+ params = parse ConfigurationParams.t_of_yojson in
    E (WorkspaceConfiguration params)
  | "workspace/workspaceFolders" -> Ok (E WorkspaceFolders)
  | "workspace/applyEdit" ->
    let+ params = parse ApplyWorkspaceEditParams.t_of_yojson in
    E (WorkspaceApplyEdit params)
  | "client/registerCapability" ->
    let+ params = parse RegistrationParams.t_of_yojson in
    E (ClientRegisterCapability params)
  | "client/unregisterCapability" ->
    let+ params = parse UnregistrationParams.t_of_yojson in
    E (ClientUnregisterCapability params)
  | "window/showMessageRequest" ->
    let+ params = parse ShowMessageRequestParams.t_of_yojson in
    E (ShowMessageRequest params)
  | m -> Ok (E (UnknownRequest (m, r.params)))

let yojson_of_result (type a) (t : a t) (r : a) : Json.t option =
  match (t, r) with
  | WorkspaceApplyEdit _, r -> Some (ApplyWorkspaceEditResponse.yojson_of_t r)
  | WorkspaceFolders, r -> Some (yojson_of_list WorkspaceFolder.yojson_of_t r)
  | WorkspaceConfiguration _, r -> Some (yojson_of_list (fun x -> x) r)
  | ClientRegisterCapability _, () -> None
  | ClientUnregisterCapability _, () -> None
  | ShowMessageRequest _, None -> None
  | ShowMessageRequest _, Some r -> Some (MessageActionItem.yojson_of_t r)
  | UnknownRequest (_, _), _ -> None

let response_of_json (type a) (t : a t) (json : Json.t) : a =
  match t with
  | WorkspaceApplyEdit _ -> ApplyWorkspaceEditResponse.t_of_yojson json
  | WorkspaceFolders -> list_of_yojson WorkspaceFolder.t_of_yojson json
  | WorkspaceConfiguration _ -> list_of_yojson (fun x -> x) json
  | ClientRegisterCapability _ -> unit_of_yojson json
  | ClientUnregisterCapability _ -> unit_of_yojson json
  | ShowMessageRequest _ -> option_of_yojson MessageActionItem.t_of_yojson json
  | UnknownRequest (_, _) -> unit_of_yojson json
