import { apiClient } from "@/lib/api/client";
import type { ApiResponse } from "@/types/auth";
import type {
  Category,
  CategoryPayload,
  PaginatedMeta,
  Product,
  ProductImportResult,
  ProductPayload,
  ProductRecipeIngredient,
  ProductRecipeResponse,
  RawMaterial,
  RawMaterialPayload,
  RawMaterialStockPayload,
  StockAlert,
  StockImportResult,
  StockMovement,
  StockMovementPayload,
  Warehouse,
} from "@/types/inventory";

interface PaginatedResponse<T> {
  data: T[];
  meta: PaginatedMeta;
}

function extractPaginated<T>(response: ApiResponse<T[]> & { meta?: PaginatedMeta }): PaginatedResponse<T> {
  return {
    data: response.data,
    meta: response.meta ?? {
      current_page: 1,
      per_page: response.data.length,
      total: response.data.length,
      last_page: 1,
    },
  };
}

export async function getProducts(params?: {
  search?: string;
  category_id?: number;
  page?: number;
  per_page?: number;
}): Promise<PaginatedResponse<Product>> {
  const { data } = await apiClient.get<ApiResponse<Product[]> & { meta?: PaginatedMeta }>(
    "/inventory/products",
    { params }
  );
  return extractPaginated(data);
}

export async function getProduct(uuid: string): Promise<Product> {
  const { data } = await apiClient.get<ApiResponse<Product>>(
    `/inventory/products/${uuid}`
  );
  return data.data;
}

export async function importProducts(file: File): Promise<ProductImportResult> {
  const formData = new FormData();
  formData.append("file", file);

  const { data } = await apiClient.post<ApiResponse<ProductImportResult>>(
    "/inventory/products/import",
    formData,
    { headers: { "Content-Type": "multipart/form-data" } },
  );

  return data.data;
}

export async function createProduct(payload: ProductPayload): Promise<Product> {
  const { data } = await apiClient.post<ApiResponse<Product>>(
    "/inventory/products",
    payload
  );
  return data.data;
}

export async function updateProduct(
  uuid: string,
  payload: Partial<ProductPayload>
): Promise<Product> {
  const { data } = await apiClient.put<ApiResponse<Product>>(
    `/inventory/products/${uuid}`,
    payload
  );
  return data.data;
}

export async function deleteProduct(uuid: string): Promise<void> {
  await apiClient.delete(`/inventory/products/${uuid}`);
}

export async function getCategories(params?: {
  search?: string;
  page?: number;
  per_page?: number;
}): Promise<PaginatedResponse<Category>> {
  const { data } = await apiClient.get<ApiResponse<Category[]> & { meta?: PaginatedMeta }>(
    "/inventory/categories",
    { params }
  );
  return extractPaginated(data);
}

export async function createCategory(payload: CategoryPayload): Promise<Category> {
  const { data } = await apiClient.post<ApiResponse<Category>>(
    "/inventory/categories",
    payload
  );
  return data.data;
}

export async function getWarehouses(): Promise<Warehouse[]> {
  const { data } = await apiClient.get<ApiResponse<Warehouse[]>>(
    "/inventory/stocks/warehouses"
  );
  return data.data;
}

export async function getStockAlerts(): Promise<StockAlert[]> {
  const { data } = await apiClient.get<ApiResponse<StockAlert[]>>(
    "/inventory/stocks/alerts"
  );
  return data.data;
}

export async function getStockMovements(params?: {
  product_id?: number;
  page?: number;
  per_page?: number;
}): Promise<PaginatedResponse<StockMovement>> {
  const { data } = await apiClient.get<ApiResponse<StockMovement[]> & { meta?: PaginatedMeta }>(
    "/inventory/stocks/movements",
    { params }
  );
  return extractPaginated(data);
}

export async function stockIn(payload: StockMovementPayload): Promise<void> {
  await apiClient.post("/inventory/stocks/in", payload);
}

export async function stockOut(payload: StockMovementPayload): Promise<void> {
  await apiClient.post("/inventory/stocks/out", payload);
}

export async function stockAdjustment(payload: StockMovementPayload): Promise<void> {
  await apiClient.post("/inventory/stocks/adjustment", payload);
}

export async function importStock(
  file: File,
  warehouseId?: number,
): Promise<StockImportResult> {
  const formData = new FormData();
  formData.append("file", file);
  if (warehouseId) {
    formData.append("warehouse_id", String(warehouseId));
  }

  const { data } = await apiClient.post<ApiResponse<StockImportResult>>(
    "/inventory/stocks/import",
    formData,
    { headers: { "Content-Type": "multipart/form-data" } },
  );

  return data.data;
}

export async function getRawMaterials(params?: {
  search?: string;
  is_active?: boolean;
  page?: number;
  per_page?: number;
}): Promise<PaginatedResponse<RawMaterial>> {
  const { data } = await apiClient.get<ApiResponse<RawMaterial[]> & { meta?: PaginatedMeta }>(
    "/inventory/raw-materials",
    { params }
  );
  return extractPaginated(data);
}

export async function getRawMaterialAlerts(): Promise<RawMaterial[]> {
  const { data } = await apiClient.get<ApiResponse<RawMaterial[]>>(
    "/inventory/raw-materials/alerts"
  );
  return data.data;
}

export async function createRawMaterial(payload: RawMaterialPayload): Promise<RawMaterial> {
  const { data } = await apiClient.post<ApiResponse<RawMaterial>>(
    "/inventory/raw-materials",
    payload
  );
  return data.data;
}

export async function updateRawMaterial(
  id: number,
  payload: Partial<RawMaterialPayload>
): Promise<RawMaterial> {
  const { data } = await apiClient.put<ApiResponse<RawMaterial>>(
    `/inventory/raw-materials/${id}`,
    payload
  );
  return data.data;
}

export async function deleteRawMaterial(id: number): Promise<void> {
  await apiClient.delete(`/inventory/raw-materials/${id}`);
}

export async function rawMaterialStockIn(
  id: number,
  payload: RawMaterialStockPayload
): Promise<RawMaterial> {
  const { data } = await apiClient.post<ApiResponse<RawMaterial>>(
    `/inventory/raw-materials/${id}/stock-in`,
    payload
  );
  return data.data;
}

export async function rawMaterialStockOut(
  id: number,
  payload: RawMaterialStockPayload
): Promise<RawMaterial> {
  const { data } = await apiClient.post<ApiResponse<RawMaterial>>(
    `/inventory/raw-materials/${id}/stock-out`,
    payload
  );
  return data.data;
}

export async function getProductRecipe(uuid: string): Promise<ProductRecipeResponse> {
  const { data } = await apiClient.get<ApiResponse<ProductRecipeResponse>>(
    `/inventory/products/${uuid}/recipe`
  );
  return data.data;
}

export async function syncProductRecipe(
  uuid: string,
  ingredients: ProductRecipeIngredient[]
): Promise<ProductRecipeResponse> {
  const { data } = await apiClient.put<ApiResponse<ProductRecipeResponse>>(
    `/inventory/products/${uuid}/recipe`,
    { ingredients }
  );
  return data.data;
}

export async function getProductCogs(uuid: string): Promise<{ cogs: number }> {
  const { data } = await apiClient.get<ApiResponse<{ cogs: number }>>(
    `/inventory/products/${uuid}/cogs`
  );
  return data.data;
}