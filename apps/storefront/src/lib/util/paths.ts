// utils/paths.js
import path from "path"
import { fileURLToPath } from "url"
// 获取当前文件的目录路径
const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
// 获取项目根目录
export const rootDir = path.resolve(__dirname, "../../../../../")

// 常用目录路径
export const paths = {
  public: path.resolve(rootDir, "public"),
  media: path.resolve(rootDir, "public/media"),
  // uploads: path.resolve(rootDir, "public/uploads"),
}
