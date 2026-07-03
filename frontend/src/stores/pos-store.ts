import { create } from "zustand";
import {
  buildCartItemKey,
  calcUnitPrice,
  type CartItem,
  type PosProduct,
  type SelectedModifier,
} from "@/types/pos";

interface PosState {
  items: CartItem[];
  addItem: (product: PosProduct) => void;
  addItemWithModifiers: (
    product: PosProduct,
    modifiers: SelectedModifier[],
    quantity?: number
  ) => void;
  removeItem: (key: string) => void;
  updateQuantity: (key: string, quantity: number) => boolean;
  clearCart: () => void;
  subtotal: () => number;
  itemCount: () => number;
}

export const usePosStore = create<PosState>((set, get) => ({
  items: [],

  addItem: (product) => {
    const hasModifiers = (product.modifier_groups?.length ?? 0) > 0;
    if (hasModifiers) return;

    get().addItemWithModifiers(product, [], 1);
  },

  addItemWithModifiers: (product, modifiers, quantity = 1) => {
    const key = buildCartItemKey(product.id, modifiers);
    const unitPrice = calcUnitPrice(product.base_price, modifiers);

    set((state) => {
      const existing = state.items.find((i) => i.key === key);

      if (existing) {
        return {
          items: state.items.map((i) =>
            i.key === key ? { ...i, quantity: i.quantity + quantity } : i
          ),
        };
      }

      return {
        items: [
          ...state.items,
          { key, product, quantity, modifiers, unitPrice },
        ],
      };
    });
  },

  removeItem: (key) => {
    set((state) => ({
      items: state.items.filter((i) => i.key !== key),
    }));
  },

  updateQuantity: (key, quantity) => {
    if (quantity <= 0) {
      get().removeItem(key);
      return true;
    }

    const item = get().items.find((i) => i.key === key);
    if (!item) return false;

    if (
      item.product.track_stock &&
      quantity > item.product.total_stock
    ) {
      return false;
    }

    set((state) => ({
      items: state.items.map((i) =>
        i.key === key ? { ...i, quantity } : i
      ),
    }));
    return true;
  },

  clearCart: () => set({ items: [] }),

  subtotal: () =>
    get().items.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0),

  itemCount: () =>
    get().items.reduce((sum, item) => sum + item.quantity, 0),
}));