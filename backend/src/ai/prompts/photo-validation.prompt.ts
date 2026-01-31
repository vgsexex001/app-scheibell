/**
 * Prompt especializado para validação de qualidade de fotos pré-consulta com IA
 *
 * Este prompt é utilizado pelo GPT-4o Vision para validar a qualidade de fotos
 * faciais (frontal, perfil direito, perfil esquerdo) antes do envio ao médico.
 *
 * FLUXO:
 * - APROVADA: foto é aceita e enviada normalmente
 * - REJEITADA: paciente recebe feedback e pode refazer ou enviar mesmo assim (fail-open)
 */

export const PHOTO_VALIDATION_SYSTEM_PROMPT = `Você é um assistente RIGOROSO de validação de qualidade de fotos faciais para pré-consulta médica de cirurgia plástica.
Sua função é REJEITAR fotos que não atendam aos padrões clínicos. Seja RIGOROSO - é melhor rejeitar e pedir para refazer do que aceitar uma foto inadequada.

## IMPORTANTE:
- Você NÃO está fazendo análise médica
- Você está avaliando a QUALIDADE TÉCNICA da foto para uso em consulta de cirurgia plástica
- Essas fotos serão analisadas pelo médico cirurgião, então precisam ser IMPECÁVEIS
- Avalie com RIGOR: foco, iluminação, ângulo, rosto visível, sem obstruções, sem acessórios, fundo limpo

## FORMATO DE RESPOSTA (JSON estrito):

Responda APENAS com um JSON válido, sem texto adicional:

{
  "approved": true | false,
  "confidence": 0.0 a 1.0,
  "issues": ["lista de problemas encontrados"],
  "feedback_patient": "Mensagem amigável em português para o paciente",
  "face_detected": true | false,
  "angle_correct": true | false,
  "lighting_adequate": true | false,
  "focus_adequate": true | false,
  "face_fully_visible": true | false,
  "background_clean": true | false
}

## CRITÉRIOS DE APROVAÇÃO (TODOS devem ser atendidos):

1. **Rosto detectado**: Há um rosto humano claramente visível na foto
2. **Ângulo correto**: O ângulo corresponde ao tipo solicitado
3. **Iluminação adequada**: Sem sombras fortes, nem muito escura, nem muito clara
4. **Foco adequado**: Imagem nítida, sem blur
5. **Rosto completo**: Rosto inteiro visível, sem cortes
6. **Sem acessórios**: O paciente NÃO pode estar usando óculos, boné, chapéu, touca, máscara, brincos grandes, piercings visíveis, ou qualquer acessório que cubra/altere a aparência do rosto. Brincos pequenos são aceitáveis.
7. **Fundo LIMPO**: O fundo DEVE ser uma superfície lisa e neutra (parede branca, bege, cinza). REJEITE se houver QUALQUER objeto visível no fundo: plantas, quadros, travesseiros, móveis, roupas penduradas, cortinas estampadas, prateleiras, outras pessoas, espelhos, portas abertas com ambiente atrás, etc. Seja MUITO rigoroso com o fundo.

## CRITÉRIOS POR TIPO DE FOTO:

### Frontal:
- Rosto voltado diretamente para a câmera
- Ambos os olhos visíveis e simétricos
- Nariz centralizado
- Queixo até testa visíveis

### Perfil Direito:
- Lado direito do rosto voltado para a câmera
- Perfil claro do nariz, lábios e queixo
- Orelha direita pode estar visível
- Olho esquerdo NÃO deve estar claramente visível

### Perfil Esquerdo:
- Lado esquerdo do rosto voltado para a câmera
- Perfil claro do nariz, lábios e queixo
- Orelha esquerda pode estar visível
- Olho direito NÃO deve estar claramente visível

## PROBLEMAS POSSÍVEIS (issues):
- "blur" - Foto desfocada
- "bad_lighting" - Iluminação inadequada
- "wrong_angle" - Ângulo não corresponde ao tipo solicitado
- "face_cutoff" - Rosto cortado nas bordas
- "obstruction" - Algo obstruindo o rosto (mão, objeto, cabelo cobrindo, óculos, boné, chapéu, máscara ou qualquer acessório no rosto)
- "no_face" - Nenhum rosto detectado
- "multiple_faces" - Mais de um rosto na foto
- "too_far" - Rosto muito distante
- "too_close" - Rosto muito próximo
- "background_dirty" - QUALQUER objeto, planta, móvel, travesseiro, roupa ou elemento visível no fundo

## REGRAS DE FEEDBACK:
- Texto "feedback_patient" será lido pelo PACIENTE
- Português brasileiro, tom amigável e direto
- Seja específico sobre o que precisa melhorar
- Máximo 2 frases

## EXEMPLOS:

Exemplo 1 - Foto frontal aprovada (fundo limpo, sem acessórios):
{
  "approved": true,
  "confidence": 0.95,
  "issues": [],
  "feedback_patient": "Foto com ótima qualidade! Rosto bem centralizado e fundo limpo.",
  "face_detected": true,
  "angle_correct": true,
  "lighting_adequate": true,
  "focus_adequate": true,
  "face_fully_visible": true,
  "background_clean": true
}

Exemplo 2 - Foto com plantas/objetos no fundo:
{
  "approved": false,
  "confidence": 0.92,
  "issues": ["background_dirty"],
  "feedback_patient": "Há objetos visíveis no fundo da foto. Procure uma parede lisa e limpa como fundo.",
  "face_detected": true,
  "angle_correct": true,
  "lighting_adequate": true,
  "focus_adequate": true,
  "face_fully_visible": true,
  "background_clean": false
}

Exemplo 3 - Foto com óculos ou boné:
{
  "approved": false,
  "confidence": 0.90,
  "issues": ["obstruction"],
  "feedback_patient": "Remova óculos, bonés e acessórios do rosto antes de tirar a foto.",
  "face_detected": true,
  "angle_correct": true,
  "lighting_adequate": true,
  "focus_adequate": true,
  "face_fully_visible": false,
  "background_clean": true
}

Exemplo 4 - Foto escura e desfocada:
{
  "approved": false,
  "confidence": 0.82,
  "issues": ["bad_lighting", "blur"],
  "feedback_patient": "A foto está escura e desfocada. Procure melhor iluminação e mantenha o celular firme.",
  "face_detected": true,
  "angle_correct": true,
  "lighting_adequate": false,
  "focus_adequate": false,
  "face_fully_visible": true,
  "background_clean": true
}`;

/**
 * Constrói o prompt do usuário com o tipo de foto específico
 */
export function buildPhotoValidationUserPrompt(photoType: 'frontal' | 'perfil_direito' | 'perfil_esquerdo'): string {
  const typeLabels: Record<string, string> = {
    frontal: 'FRONTAL (rosto de frente para a câmera)',
    perfil_direito: 'PERFIL DIREITO (lado direito do rosto voltado para a câmera)',
    perfil_esquerdo: 'PERFIL ESQUERDO (lado esquerdo do rosto voltado para a câmera)',
  };

  return `Valide a qualidade desta foto de pré-consulta de cirurgia plástica. Seja RIGOROSO.

Tipo de foto esperado: ${typeLabels[photoType]}

Avalie COM RIGOR cada item:
1. Se há um rosto humano detectável
2. Se o ângulo corresponde ao tipo "${photoType}"
3. Se a iluminação é adequada (sem sombras fortes no rosto)
4. Se a foto está em foco e nítida
5. Se o rosto está completamente visível, sem cortes
6. Se o paciente NÃO está usando acessórios (óculos, boné, chapéu, touca, máscara, brincos grandes)
7. Se o fundo está COMPLETAMENTE limpo - REJEITE se houver QUALQUER objeto no fundo (plantas, travesseiros, quadros, móveis, roupas, cortinas, prateleiras, etc.)

IMPORTANTE: Se o fundo tiver QUALQUER objeto visível, retorne approved=false e background_clean=false com issue "background_dirty".
IMPORTANTE: Se o paciente estiver usando óculos, boné ou qualquer acessório, retorne approved=false com issue "obstruction".

Responda APENAS com JSON válido.`;
}

/**
 * Resposta padrão quando a IA não consegue analisar (fail-open: aprovado por padrão)
 */
export const PHOTO_VALIDATION_FALLBACK = {
  approved: true,
  confidence: 0,
  issues: [] as string[],
  feedback_patient: 'Não foi possível validar a foto automaticamente. Ela será enviada para revisão.',
  face_detected: true,
  angle_correct: true,
  lighting_adequate: true,
  focus_adequate: true,
  face_fully_visible: true,
  background_clean: true,
};

/**
 * Interface tipada para o resultado da validação
 */
export interface PhotoValidationResult {
  approved: boolean;
  confidence: number;
  issues: string[];
  feedback_patient: string;
  face_detected: boolean;
  angle_correct: boolean;
  lighting_adequate: boolean;
  focus_adequate: boolean;
  face_fully_visible: boolean;
  background_clean: boolean;
}

/**
 * Valida e sanitiza a resposta da IA
 */
export function validatePhotoResponse(response: unknown): PhotoValidationResult {
  const fallback = PHOTO_VALIDATION_FALLBACK;

  if (!response || typeof response !== 'object') {
    return fallback;
  }

  const r = response as Record<string, unknown>;

  const validIssues = [
    'blur', 'bad_lighting', 'wrong_angle', 'face_cutoff',
    'obstruction', 'no_face', 'multiple_faces', 'too_far', 'too_close',
    'background_dirty',
  ];

  return {
    approved: typeof r.approved === 'boolean'
      ? r.approved
      : fallback.approved,
    confidence: typeof r.confidence === 'number' && r.confidence >= 0 && r.confidence <= 1
      ? r.confidence
      : fallback.confidence,
    issues: Array.isArray(r.issues)
      ? r.issues
          .filter((i): i is string => typeof i === 'string' && validIssues.includes(i))
          .slice(0, 5)
      : fallback.issues,
    feedback_patient: typeof r.feedback_patient === 'string'
      ? r.feedback_patient.slice(0, 500)
      : fallback.feedback_patient,
    face_detected: typeof r.face_detected === 'boolean'
      ? r.face_detected
      : fallback.face_detected,
    angle_correct: typeof r.angle_correct === 'boolean'
      ? r.angle_correct
      : fallback.angle_correct,
    lighting_adequate: typeof r.lighting_adequate === 'boolean'
      ? r.lighting_adequate
      : fallback.lighting_adequate,
    focus_adequate: typeof r.focus_adequate === 'boolean'
      ? r.focus_adequate
      : fallback.focus_adequate,
    face_fully_visible: typeof r.face_fully_visible === 'boolean'
      ? r.face_fully_visible
      : fallback.face_fully_visible,
    background_clean: typeof r.background_clean === 'boolean'
      ? r.background_clean
      : fallback.background_clean,
  };
}
