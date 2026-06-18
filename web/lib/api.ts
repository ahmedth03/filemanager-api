import axios from 'axios'
import Cookies from 'js-cookie'

const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api/v1'

export const api = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
  withCredentials: false,
})

api.interceptors.request.use((config) => {
  const token = Cookies.get('access_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original = error.config
    if (error.response?.status === 401 && !original._retry) {
      original._retry = true
      const refreshToken = Cookies.get('refresh_token')
      if (refreshToken) {
        try {
          const { data } = await axios.post(`${BASE_URL}/auth/refresh`, { refreshToken })
          const tokens = data.data || data
          Cookies.set('access_token', tokens.accessToken, { expires: 1/96 }) // 15 min
          Cookies.set('refresh_token', tokens.refreshToken, { expires: 7 })
          original.headers.Authorization = `Bearer ${tokens.accessToken}`
          return api(original)
        } catch {
          Cookies.remove('access_token')
          Cookies.remove('refresh_token')
          Cookies.remove('user')
          window.location.href = '/login'
        }
      } else {
        window.location.href = '/login'
      }
    }
    return Promise.reject(error)
  }
)

// Extract data from wrapped response
export function unwrap<T>(response: any): T {
  return response.data?.data ?? response.data
}

export function unwrapPaginated<T>(response: any): { data: T[]; meta: any } {
  const d = response.data?.data ?? response.data
  if (Array.isArray(d)) return { data: d, meta: { total: d.length, page: 1, limit: d.length, totalPages: 1 } }
  return { data: d?.data ?? [], meta: d?.meta ?? {} }
}
