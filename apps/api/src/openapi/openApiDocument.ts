import type { INestApplication } from '@nestjs/common';
import { DocumentBuilder, type OpenAPIObject, SwaggerModule } from '@nestjs/swagger';

export const API_VERSION = '0.1.0';
export const SWAGGER_PATH = 'docs';

export function buildOpenApiDocument(app: INestApplication): OpenAPIObject {
  const config = new DocumentBuilder()
    .setTitle('FlowWave API')
    .setDescription(
      'Sync API for FlowWave, a privacy-first personal energy and focus rhythm application. ' +
        'FlowWave estimates are personal rhythm estimates, not medical assessments or diagnoses.',
    )
    .setVersion(API_VERSION)
    .build();
  return SwaggerModule.createDocument(app, config);
}

export function setupSwagger(app: INestApplication): void {
  SwaggerModule.setup(SWAGGER_PATH, app, () => buildOpenApiDocument(app), {
    jsonDocumentUrl: `${SWAGGER_PATH}/openapi.json`,
  });
}
