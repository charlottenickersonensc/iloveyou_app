export type FruitSeed = {
  id: string;
  code: string;
  name: string;
  themeColorHex: string;
  badgeAssetName: string;
  wheelIndex: number;
};

export const FRUIT_COMMUNITIES: FruitSeed[] = [
  {
    id: "apple", code: "apple", name: "Apple", themeColorHex: "#D94A38",
    badgeAssetName: "fruit_apple", wheelIndex: 0
  },
  {
    id: "banana", code: "banana", name: "Banana", themeColorHex: "#F0C84B",
    badgeAssetName: "fruit_banana", wheelIndex: 1
  },
  {
    id: "cherry", code: "cherry", name: "Cherry", themeColorHex: "#C72C48",
    badgeAssetName: "fruit_cherry", wheelIndex: 2
  },
  {
    id: "grape", code: "grape", name: "Grape", themeColorHex: "#7652A8",
    badgeAssetName: "fruit_grape", wheelIndex: 3
  },
  {
    id: "kiwi", code: "kiwi", name: "Kiwi", themeColorHex: "#6E9F3D",
    badgeAssetName: "fruit_kiwi", wheelIndex: 4
  },
  {
    id: "lemon", code: "lemon", name: "Lemon", themeColorHex: "#E4CF3B",
    badgeAssetName: "fruit_lemon", wheelIndex: 5
  },
  {
    id: "mango", code: "mango", name: "Mango", themeColorHex: "#EE8F2E",
    badgeAssetName: "fruit_mango", wheelIndex: 6
  },
  {
    id: "orange", code: "orange", name: "Orange", themeColorHex: "#E97826",
    badgeAssetName: "fruit_orange", wheelIndex: 7
  },
  {
    id: "peach", code: "peach", name: "Peach", themeColorHex: "#EF9F88",
    badgeAssetName: "fruit_peach", wheelIndex: 8
  },
  {
    id: "pear", code: "pear", name: "Pear", themeColorHex: "#9DBB48",
    badgeAssetName: "fruit_pear", wheelIndex: 9
  },
  {
    id: "pineapple", code: "pineapple", name: "Pineapple", themeColorHex: "#D8A329",
    badgeAssetName: "fruit_pineapple", wheelIndex: 10
  },
  {
    id: "strawberry", code: "strawberry", name: "Strawberry", themeColorHex: "#D93B52",
    badgeAssetName: "fruit_strawberry", wheelIndex: 11
  }
];
