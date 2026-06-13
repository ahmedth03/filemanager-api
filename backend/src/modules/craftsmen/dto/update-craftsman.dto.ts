import { PartialType } from '@nestjs/swagger';
import { CreateCraftsmanDto } from './create-craftsman.dto';

export class UpdateCraftsmanDto extends PartialType(CreateCraftsmanDto) {}
