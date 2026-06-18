import Cookies from 'js-cookie'

export interface User {
  id: string
  email: string
  firstName: string
  lastName: string
  phone?: string
  avatarUrl?: string
  role: string
  status: string
}

export function getUser(): User | null {
  try {
    const u = Cookies.get('user')
    return u ? JSON.parse(u) : null
  } catch { return null }
}

export function setAuth(accessToken: string, refreshToken: string, user: User) {
  Cookies.set('access_token', accessToken, { expires: 1/96 }) // 15 min
  Cookies.set('refresh_token', refreshToken, { expires: 7 })
  Cookies.set('user', JSON.stringify(user), { expires: 7 })
}

export function clearAuth() {
  Cookies.remove('access_token')
  Cookies.remove('refresh_token')
  Cookies.remove('user')
}

export function isLoggedIn(): boolean {
  return !!Cookies.get('access_token') || !!Cookies.get('refresh_token')
}
