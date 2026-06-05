import { CollectionListItem } from "./interface/api/CollectionApiInterface";
import { StationListItemReturning } from "./interface/api/HomeApiInterface";
import { OrderListItem } from "./interface/api/OrderApiInterface";

export class Tmp {
  list: StationListItemReturning[] | CollectionListItem[] | OrderListItem[] = []
}