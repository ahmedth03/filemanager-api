import { IsEmail, IsString, MinLength, IsOptional, IsEnum, Matches } from 'class-validator';
import { Transform } from 'class-transformer';

export class RegisterDto {
  @IsString()
  firstName: string;

  @IsString()
  lastName: string;

  @IsEmail()
  @Transform(({ value }) => value.toLowerCase().trim())
  email: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsOptional()
  @IsString()
  @Matches(/^\+?[0-9]{9,15}$/)
  phone?: string;

  @IsOptional()
  @IsEnum(['USER', 'CRAFTSMAN', 'OWNER'])
  role?: string;
}
