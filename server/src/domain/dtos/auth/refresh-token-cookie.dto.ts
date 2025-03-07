import { refreshTokenCookieName } from '@/consts'

export class RefreshTokenCookieDto {
  public refreshToken: string

  private constructor({ refreshToken }: RefreshTokenCookieDto) {
    this.refreshToken = refreshToken
  }

  static create(input: any): [string?, RefreshTokenCookieDto?] {
    const { [refreshTokenCookieName]: refreshToken } = input

    if (refreshToken === undefined || typeof refreshToken !== 'string') {
      return ['Invalid refresh token', undefined]
    }

    return [undefined, new RefreshTokenCookieDto({ refreshToken })]
  }
}
