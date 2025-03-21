import { paramsDocValidator } from '@/domain/validators/query-params/query-params.validator'

export class NumericDocDto {
  public doc: string

  private constructor({ doc }: NumericDocDto) {
    this.doc = doc
  }

  static create(input: any): [string?, NumericDocDto?] {
    const result = paramsDocValidator(input)

    if (!result.success) {
      return ['Id inválido', undefined]
    }

    return [undefined, new NumericDocDto(result.data)]
  }
}
