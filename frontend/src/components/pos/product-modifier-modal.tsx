"use client";

import { useEffect, useMemo, useState } from "react";
import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { formatCurrency } from "@/lib/utils/format";
import {
  calcUnitPrice,
  type PosProduct,
  type ProductModifierGroup,
  type SelectedModifier,
} from "@/types/pos";

interface ProductModifierModalProps {
  open: boolean;
  product: PosProduct | null;
  onClose: () => void;
  onConfirm: (modifiers: SelectedModifier[]) => void;
}

function buildDefaultSelections(groups: ProductModifierGroup[]): Record<number, number[]> {
  const selections: Record<number, number[]> = {};

  for (const group of groups) {
    const defaults = group.modifiers.filter((m) => m.is_default).map((m) => m.id);

    if (defaults.length > 0) {
      selections[group.id] = defaults.slice(0, group.max_select);
    } else if (group.max_select === 1 && group.modifiers.length === 1) {
      selections[group.id] = [group.modifiers[0].id];
    } else {
      selections[group.id] = [];
    }
  }

  return selections;
}

function toSelectedModifiers(
  product: PosProduct,
  selections: Record<number, number[]>
): SelectedModifier[] {
  const groups = product.modifier_groups ?? [];
  const selected: SelectedModifier[] = [];

  for (const group of groups) {
    const ids = selections[group.id] ?? [];

    for (const modifierId of ids) {
      const modifier = group.modifiers.find((m) => m.id === modifierId);
      if (!modifier) continue;

      selected.push({
        modifier_id: modifier.id,
        group_id: group.id,
        group_name: group.name,
        name: modifier.name,
        price_adjustment: modifier.price_adjustment,
      });
    }
  }

  return selected;
}

function isSelectionValid(
  groups: ProductModifierGroup[],
  selections: Record<number, number[]>
): boolean {
  return groups.every((group) => {
    const count = (selections[group.id] ?? []).length;

    if (group.is_required && count < Math.max(1, group.min_select)) {
      return false;
    }

    if (count < group.min_select) {
      return false;
    }

    if (count > group.max_select) {
      return false;
    }

    return true;
  });
}

export function ProductModifierModal({
  open,
  product,
  onClose,
  onConfirm,
}: ProductModifierModalProps) {
  const groups = useMemo(
    () => product?.modifier_groups ?? [],
    [product]
  );

  const [selections, setSelections] = useState<Record<number, number[]>>({});

  useEffect(() => {
    if (!open || !product) return;
    setSelections(buildDefaultSelections(groups));
  }, [open, product, groups]);

  if (!open || !product) return null;

  const selectedModifiers = toSelectedModifiers(product, selections);
  const unitPrice = calcUnitPrice(product.base_price, selectedModifiers);
  const canConfirm = isSelectionValid(groups, selections);
  const outOfStock = product.track_stock && product.total_stock <= 0;

  const toggleCheckbox = (group: ProductModifierGroup, modifierId: number) => {
    setSelections((prev) => {
      const current = prev[group.id] ?? [];

      if (current.includes(modifierId)) {
        return { ...prev, [group.id]: current.filter((id) => id !== modifierId) };
      }

      if (current.length >= group.max_select) {
        return prev;
      }

      return { ...prev, [group.id]: [...current, modifierId] };
    });
  };

  const selectRadio = (groupId: number, modifierId: number) => {
    setSelections((prev) => ({ ...prev, [groupId]: [modifierId] }));
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 p-0 sm:items-center sm:p-4">
      <div className="flex max-h-[90vh] w-full max-w-lg flex-col rounded-t-xl bg-white shadow-xl sm:rounded-xl">
        <div className="flex items-start justify-between border-b border-border px-6 py-4">
          <div>
            <h2 className="text-lg font-semibold">{product.name}</h2>
            <p className="text-sm text-muted-foreground">
              Base {formatCurrency(product.base_price)}
              {selectedModifiers.length > 0 && (
                <> · Total {formatCurrency(unitPrice)}</>
              )}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg p-1 hover:bg-slate-100"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="flex-1 space-y-5 overflow-y-auto p-6">
          {outOfStock && (
            <div className="rounded-lg bg-amber-50 px-3 py-2 text-sm text-amber-800">
              Stok produk habis. Tambahkan stok di Inventori sebelum menjual.
            </div>
          )}
          {groups.map((group) => {
            const selected = selections[group.id] ?? [];
            const isRadio = group.max_select === 1;

            return (
              <div key={group.id} className="space-y-2">
                <div className="flex items-center gap-2">
                  <p className="text-sm font-medium">{group.name}</p>
                  {group.is_required && (
                    <span className="rounded bg-amber-100 px-1.5 py-0.5 text-[10px] font-medium text-amber-700">
                      Wajib
                    </span>
                  )}
                  {!isRadio && group.max_select > 1 && (
                    <span className="text-[10px] text-muted-foreground">
                      Maks. {group.max_select}
                    </span>
                  )}
                </div>

                <div className="space-y-2">
                  {group.modifiers.map((modifier) => {
                    const checked = selected.includes(modifier.id);
                    const inputId = `modifier-${group.id}-${modifier.id}`;

                    return (
                      <label
                        key={modifier.id}
                        htmlFor={inputId}
                        className={`flex cursor-pointer items-center justify-between rounded-lg border px-3 py-2.5 transition-colors ${
                          checked
                            ? "border-primary bg-primary/5"
                            : "border-border hover:border-primary/40"
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          <input
                            id={inputId}
                            type={isRadio ? "radio" : "checkbox"}
                            name={`group-${group.id}`}
                            checked={checked}
                            onChange={() =>
                              isRadio
                                ? selectRadio(group.id, modifier.id)
                                : toggleCheckbox(group, modifier.id)
                            }
                            className="h-4 w-4 accent-primary"
                          />
                          <span className="text-sm">{modifier.name}</span>
                        </div>
                        {modifier.price_adjustment !== 0 && (
                          <span className="text-xs font-medium text-muted-foreground">
                            {modifier.price_adjustment > 0 ? "+" : ""}
                            {formatCurrency(modifier.price_adjustment)}
                          </span>
                        )}
                      </label>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>

        <div className="flex items-center justify-between gap-3 border-t border-border px-6 py-4">
          <div>
            <p className="text-xs text-muted-foreground">Harga item</p>
            <p className="text-lg font-bold text-primary">
              {formatCurrency(unitPrice)}
            </p>
          </div>
          <div className="flex gap-2">
            <Button variant="outline" onClick={onClose}>
              Batal
            </Button>
            <Button
              disabled={!canConfirm || outOfStock}
              onClick={() => onConfirm(selectedModifiers)}
            >
              Tambah ke Keranjang
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}