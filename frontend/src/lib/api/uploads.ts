import { apiClient } from "@/lib/api/client";
import type { ApiResponse } from "@/types/auth";

export interface UploadResult {
  url: string;
  path: string;
  type: string;
  original_name: string;
  size: number;
}

export async function uploadFile(
  file: File,
  type: "logo" | "product" | "general" = "general"
): Promise<UploadResult> {
  const formData = new FormData();
  formData.append("file", file);
  formData.append("type", type);

  const { data } = await apiClient.post<ApiResponse<UploadResult>>(
    "/uploads",
    formData,
    {
      headers: { "Content-Type": undefined },
    }
  );

  return data.data;
}