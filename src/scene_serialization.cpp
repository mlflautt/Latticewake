#include "scene_serialization.hpp"

#include <charconv>
#include <cmath>
#include <cstdlib>
#include <limits>
#include <map>
#include <set>
#include <sstream>
#include <utility>
#include <variant>

namespace latticewake {
namespace {

struct Json;
using JsonArray = std::vector<Json>;
using JsonObject = std::map<std::string, Json, std::less<>>;
struct Json {
  using Value = std::variant<std::nullptr_t, bool, double, std::string, JsonArray, JsonObject>;
  Value value;
};

class Parser {
 public:
  explicit Parser(const std::string_view source) : source_(source) {}

  std::optional<Json> parse(SceneSerializationError& error) {
    skipWhitespace();
    const auto value = parseValue(error);
    if (!value) return std::nullopt;
    skipWhitespace();
    if (position_ != source_.size()) return fail<Json>(error, "$", "trailing content");
    return value;
  }

 private:
  template <typename T>
  std::optional<T> fail(SceneSerializationError& error, const std::string_view path,
                        const std::string_view message) {
    error = {std::string(path), std::string(message)};
    return std::nullopt;
  }
  void skipWhitespace() {
    while (position_ < source_.size() && (source_[position_] == ' ' || source_[position_] == '\n' ||
                                          source_[position_] == '\r' || source_[position_] == '\t')) ++position_;
  }
  bool consume(const char c) {
    if (position_ < source_.size() && source_[position_] == c) { ++position_; return true; }
    return false;
  }
  std::optional<Json> parseValue(SceneSerializationError& error) {
    if (position_ == source_.size()) return fail<Json>(error, "$", "unexpected end of input");
    const char c = source_[position_];
    if (c == '{') return parseObject(error);
    if (c == '[') return parseArray(error);
    if (c == '"') { auto s = parseString(error); if (!s) return std::nullopt; return Json{*s}; }
    if (c == 't' && source_.substr(position_, 4) == "true") { position_ += 4; return Json{true}; }
    if (c == 'f' && source_.substr(position_, 5) == "false") { position_ += 5; return Json{false}; }
    if (c == 'n' && source_.substr(position_, 4) == "null") { position_ += 4; return Json{nullptr}; }
    if (c == '-' || (c >= '0' && c <= '9')) return parseNumber(error);
    return fail<Json>(error, "$", "invalid JSON value");
  }
  std::optional<std::string> parseString(SceneSerializationError& error) {
    if (!consume('"')) return fail<std::string>(error, "$", "expected string");
    std::string out;
    while (position_ < source_.size()) {
      const char c = source_[position_++];
      if (c == '"') return out;
      if (static_cast<unsigned char>(c) < 0x20) return fail<std::string>(error, "$", "control character in string");
      if (c != '\\') { out += c; continue; }
      if (position_ == source_.size()) return fail<std::string>(error, "$", "unfinished string escape");
      const char escaped = source_[position_++];
      switch (escaped) {
        case '"': out += '"'; break; case '\\': out += '\\'; break; case '/': out += '/'; break;
        case 'b': out += '\b'; break; case 'f': out += '\f'; break; case 'n': out += '\n'; break;
        case 'r': out += '\r'; break; case 't': out += '\t'; break;
        default: return fail<std::string>(error, "$", "unsupported string escape");
      }
    }
    return fail<std::string>(error, "$", "unterminated string");
  }
  std::optional<Json> parseNumber(SceneSerializationError& error) {
    const std::size_t begin = position_;
    if (source_[position_] == '-') ++position_;
    if (position_ == source_.size()) return fail<Json>(error, "$", "invalid number");
    if (source_[position_] == '0') ++position_;
    else { if (source_[position_] < '1' || source_[position_] > '9') return fail<Json>(error, "$", "invalid number"); while (position_ < source_.size() && source_[position_] >= '0' && source_[position_] <= '9') ++position_; }
    if (position_ < source_.size() && source_[position_] == '.') { ++position_; const auto fraction = position_; while (position_ < source_.size() && source_[position_] >= '0' && source_[position_] <= '9') ++position_; if (fraction == position_) return fail<Json>(error, "$", "invalid number fraction"); }
    if (position_ < source_.size() && (source_[position_] == 'e' || source_[position_] == 'E')) { ++position_; if (position_ < source_.size() && (source_[position_] == '+' || source_[position_] == '-')) ++position_; const auto exponent = position_; while (position_ < source_.size() && source_[position_] >= '0' && source_[position_] <= '9') ++position_; if (exponent == position_) return fail<Json>(error, "$", "invalid number exponent"); }
    const std::string text(source_.substr(begin, position_ - begin));
    char* end = nullptr;
    const double value = std::strtod(text.c_str(), &end);
    if (end != text.c_str() + text.size() || !std::isfinite(value)) return fail<Json>(error, "$", "number must be finite");
    return Json{value};
  }
  std::optional<Json> parseArray(SceneSerializationError& error) {
    consume('['); skipWhitespace(); JsonArray array;
    if (consume(']')) return Json{std::move(array)};
    while (true) { skipWhitespace(); auto value = parseValue(error); if (!value) return std::nullopt; array.push_back(std::move(*value)); skipWhitespace(); if (consume(']')) return Json{std::move(array)}; if (!consume(',')) return fail<Json>(error, "$", "expected array separator"); }
  }
  std::optional<Json> parseObject(SceneSerializationError& error) {
    consume('{'); skipWhitespace(); JsonObject object;
    if (consume('}')) return Json{std::move(object)};
    while (true) { skipWhitespace(); auto key = parseString(error); if (!key) return std::nullopt; if (object.contains(*key)) return fail<Json>(error, "$", "duplicate object field"); skipWhitespace(); if (!consume(':')) return fail<Json>(error, "$", "expected object separator"); skipWhitespace(); auto value = parseValue(error); if (!value) return std::nullopt; object.emplace(std::move(*key), std::move(*value)); skipWhitespace(); if (consume('}')) return Json{std::move(object)}; if (!consume(',')) return fail<Json>(error, "$", "expected object separator"); }
  }
  std::string_view source_; std::size_t position_{};
};

const JsonObject* object(const Json& value) { return std::get_if<JsonObject>(&value.value); }
const JsonArray* array(const Json& value) { return std::get_if<JsonArray>(&value.value); }
const std::string* string(const Json& value) { return std::get_if<std::string>(&value.value); }
const double* number(const Json& value) { return std::get_if<double>(&value.value); }
const bool* boolean(const Json& value) { return std::get_if<bool>(&value.value); }
const Json* field(const JsonObject& objectValue, const std::string_view name) { const auto it = objectValue.find(name); return it == objectValue.end() ? nullptr : &it->second; }

bool fieldsAreExact(const JsonObject& value, const std::set<std::string, std::less<>>& required,
                    const std::set<std::string, std::less<>>& optional, const std::string_view path,
                    SceneSerializationError& error) {
  for (const auto& requiredName : required) if (!value.contains(requiredName)) { error = {std::string(path), "missing field: " + requiredName}; return false; }
  for (const auto& [name, ignored] : value) { (void)ignored; if (!required.contains(name) && !optional.contains(name)) { error = {std::string(path), "unknown field: " + name}; return false; } }
  return true;
}

bool parseInteger(const Json& value, int& out, const std::string_view path, SceneSerializationError& error) {
  const double* input = number(value); if (!input || std::trunc(*input) != *input || *input < static_cast<double>(std::numeric_limits<int>::min()) || *input > static_cast<double>(std::numeric_limits<int>::max())) { error = {std::string(path), "must be a signed integer"}; return false; } out = static_cast<int>(*input); return true;
}
bool parseUnsigned32(const Json& value, std::uint32_t& out, const std::string_view path, SceneSerializationError& error) {
  const double* input = number(value); if (!input || std::trunc(*input) != *input || *input < 0.0 || *input > static_cast<double>(std::numeric_limits<std::uint32_t>::max())) { error = {std::string(path), "must be an unsigned 32-bit integer"}; return false; } out = static_cast<std::uint32_t>(*input); return true;
}
bool parseSeed(const Json& value, std::uint64_t& out, SceneSerializationError& error) {
  const std::string* input = string(value); if (!input || input->empty()) { error = {"seed", "must be a non-empty decimal string"}; return false; }
  const auto [end, code] = std::from_chars(input->data(), input->data() + input->size(), out);
  if (code != std::errc{} || end != input->data() + input->size()) { error = {"seed", "must be an unsigned 64-bit decimal string"}; return false; } return true;
}
bool requiredString(const JsonObject& value, const std::string_view name, std::string& out, const std::string_view path, SceneSerializationError& error) {
  const Json* input = field(value, name); const std::string* text = input ? string(*input) : nullptr; if (!text) { error = {std::string(path) + "." + std::string(name), "must be a string"}; return false; } out = *text; return true;
}
bool requiredNumber(const JsonObject& value, const std::string_view name, double& out, const std::string_view path, SceneSerializationError& error) {
  const Json* input = field(value, name); const double* numeric = input ? number(*input) : nullptr; if (!numeric) { error = {std::string(path) + "." + std::string(name), "must be a number"}; return false; } out = *numeric; return true;
}

void appendString(std::string& out, const std::string_view value) { out += '"'; for (const char c : value) { switch (c) { case '"': out += "\\\""; break; case '\\': out += "\\\\"; break; case '\n': out += "\\n"; break; case '\r': out += "\\r"; break; case '\t': out += "\\t"; break; default: out += c; } } out += '"'; }
void appendNumber(std::string& out, const double value) { std::ostringstream stream; stream.precision(std::numeric_limits<double>::max_digits10); stream << value; out += stream.str(); }
void appendRoleId(std::string& out, const RoleId id) { appendString(out, roleIdName(id)); }
void appendRhythm(std::string& out, const RhythmStepKind kind) { appendString(out, kind == RhythmStepKind::note ? "note" : kind == RhythmStepKind::rest ? "rest" : "tie"); }

}  // namespace

std::optional<std::string> serializeSceneV0(const Scene& scene, SceneSerializationError& error) {
  const ValidationIssues issues = validateScene(scene);
  if (!issues.empty()) { error = {issues.front().field, issues.front().message}; return std::nullopt; }
  std::string out; out.reserve(1024); out += "{\"schemaVersion\":"; appendString(out, scene.schemaVersion); out += ",\"sceneID\":"; appendString(out, scene.sceneId); out += ",\"seed\":"; appendString(out, std::to_string(scene.seed)); out += ",\"title\":"; appendString(out, scene.title); out += ",\"createdFrom\":"; if (scene.createdFrom) appendString(out, *scene.createdFrom); else out += "null";
  const auto& h = scene.harmonicContext; out += ",\"harmonicContext\":{\"tonic\":"; appendString(out, h.tonic); out += ",\"mode\":"; appendString(out, h.mode); out += ",\"scaleDegrees\":["; for (std::size_t i = 0; i < h.scaleDegrees.size(); ++i) { if (i) out += ','; out += std::to_string(h.scaleDegrees[i]); } out += "],\"chordDegree\":" + std::to_string(h.chordDegree) + ",\"chordQuality\":"; appendString(out, h.chordQuality); out += ",\"inversion\":" + std::to_string(h.inversion) + ",\"octaveReference\":" + std::to_string(h.octaveReference) + ",\"tempoBPM\":"; appendNumber(out, h.tempoBPM); out += ",\"tuningID\":"; if (h.tuningId) appendString(out, *h.tuningId); else out += "null"; out += '}';
  const auto appendTerrain = [&] { const auto& t = scene.terrain; out += ",\"terrain\":{\"kind\":"; appendString(out, t.kind); out += ",\"detail\":"; appendNumber(out,t.detail); out += ",\"zoom\":"; appendNumber(out,t.zoom); out += ",\"offsetX\":"; appendNumber(out,t.offsetX); out += ",\"offsetY\":"; appendNumber(out,t.offsetY); out += ",\"rotation\":"; appendNumber(out,t.rotation); out += ",\"motion\":"; appendNumber(out,t.motion); out += ",\"maxIterations\":" + std::to_string(t.maxIterations) + ",\"normalization\":"; appendNumber(out,t.normalization); out += '}'; }; appendTerrain();
  const auto& p = scene.path; out += ",\"path\":{\"kind\":"; appendString(out,p.kind); const std::pair<std::string_view,double> pathValues[]={{"rateRatio",p.rateRatio},{"radiusX",p.radiusX},{"radiusY",p.radiusY},{"angle",p.angle},{"translationX",p.translationX},{"translationY",p.translationY},{"meander",p.meander},{"feedback",p.feedback},{"spatialLimit",p.spatialLimit}}; for(const auto& [name,value]:pathValues){out += ",\""; out += name; out += "\":"; appendNumber(out,value);} out += '}';
  out += ",\"roles\":["; for (std::size_t i=0;i<scene.roles.size();++i) { if(i) out += ','; const auto& r=scene.roles[i]; out += "{\"id\":"; appendRoleId(out,r.id); out += ",\"enabled\":" + std::string(r.enabled ? "true" : "false") + ",\"range\":"; appendNumber(out,r.range); out += ",\"density\":"; appendNumber(out,r.density); out += ",\"pattern\":["; for(std::size_t j=0;j<r.pattern.size();++j){if(j)out+=',';out+=std::to_string(r.pattern[j]);} out += "],\"rhythm\":["; for(std::size_t j=0;j<r.rhythm.size();++j){if(j)out+=',';appendRhythm(out,r.rhythm[j].kind);} out += "],\"variation\":"; appendNumber(out,r.variation); out += ",\"seedOffset\":"; appendString(out,std::to_string(r.seedOffset)); out += ",\"voiceRoute\":"; appendString(out,r.voiceRoute); out += ",\"midiRoute\":"; appendString(out,r.midiRoute); out += '}'; } out += "]}"; return out;
}

std::optional<Scene> parseSceneV0(const std::string_view bytes, SceneSerializationError& error) {
  Parser parser(bytes); const auto root = parser.parse(error); if (!root) return std::nullopt; const JsonObject* top = object(*root); if (!top) { error={"$","must be an object"}; return std::nullopt; }
  const std::set<std::string,std::less<>> topRequired={"schemaVersion","sceneID","seed","title","harmonicContext","terrain","path","roles"}; const std::set<std::string,std::less<>> topOptional={"createdFrom"}; if(!fieldsAreExact(*top,topRequired,topOptional,"$",error))return std::nullopt;
  Scene scene; if(!requiredString(*top,"schemaVersion",scene.schemaVersion,"$",error)||!requiredString(*top,"sceneID",scene.sceneId,"$",error)||!parseSeed(*field(*top,"seed"),scene.seed,error)||!requiredString(*top,"title",scene.title,"$",error)) return std::nullopt;
  if(const Json* parent=field(*top,"createdFrom")){if(std::holds_alternative<std::nullptr_t>(parent->value))scene.createdFrom=std::nullopt;else {const auto* value=string(*parent);if(!value){error={"createdFrom","must be a string or null"};return std::nullopt;}scene.createdFrom=*value;}}
  const JsonObject* h=object(*field(*top,"harmonicContext")); if(!h){error={"harmonicContext","must be an object"};return std::nullopt;} const std::set<std::string,std::less<>> harmonicRequired={"tonic","mode","scaleDegrees","chordDegree","chordQuality","inversion","octaveReference","tempoBPM"}; const std::set<std::string,std::less<>> harmonicOptional={"tuningID"}; if(!fieldsAreExact(*h,harmonicRequired,harmonicOptional,"harmonicContext",error))return std::nullopt; auto& hc=scene.harmonicContext; if(!requiredString(*h,"tonic",hc.tonic,"harmonicContext",error)||!requiredString(*h,"mode",hc.mode,"harmonicContext",error)||!requiredString(*h,"chordQuality",hc.chordQuality,"harmonicContext",error)||!requiredNumber(*h,"tempoBPM",hc.tempoBPM,"harmonicContext",error)||!parseInteger(*field(*h,"chordDegree"),hc.chordDegree,"harmonicContext.chordDegree",error)||!parseInteger(*field(*h,"inversion"),hc.inversion,"harmonicContext.inversion",error)||!parseInteger(*field(*h,"octaveReference"),hc.octaveReference,"harmonicContext.octaveReference",error))return std::nullopt; const JsonArray* degrees=array(*field(*h,"scaleDegrees"));if(!degrees){error={"harmonicContext.scaleDegrees","must be an array"};return std::nullopt;}for(const auto& degree:*degrees){int parsed{};if(!parseInteger(degree,parsed,"harmonicContext.scaleDegrees",error))return std::nullopt;hc.scaleDegrees.push_back(parsed);}if(const Json* tuning=field(*h,"tuningID")){if(!std::holds_alternative<std::nullptr_t>(tuning->value)){const auto* value=string(*tuning);if(!value){error={"harmonicContext.tuningID","must be a string or null"};return std::nullopt;}hc.tuningId=*value;}}
  const JsonObject* t=object(*field(*top,"terrain")); if(!t){error={"terrain","must be an object"};return std::nullopt;} const std::set<std::string,std::less<>> terrainFields={"kind","detail","zoom","offsetX","offsetY","rotation","motion","maxIterations","normalization"}; if(!fieldsAreExact(*t,terrainFields,{},"terrain",error))return std::nullopt; auto& terrain=scene.terrain; if(!requiredString(*t,"kind",terrain.kind,"terrain",error)||!requiredNumber(*t,"detail",terrain.detail,"terrain",error)||!requiredNumber(*t,"zoom",terrain.zoom,"terrain",error)||!requiredNumber(*t,"offsetX",terrain.offsetX,"terrain",error)||!requiredNumber(*t,"offsetY",terrain.offsetY,"terrain",error)||!requiredNumber(*t,"rotation",terrain.rotation,"terrain",error)||!requiredNumber(*t,"motion",terrain.motion,"terrain",error)||!requiredNumber(*t,"normalization",terrain.normalization,"terrain",error)||!parseUnsigned32(*field(*t,"maxIterations"),terrain.maxIterations,"terrain.maxIterations",error))return std::nullopt;
  const JsonObject* p=object(*field(*top,"path"));if(!p){error={"path","must be an object"};return std::nullopt;}const std::set<std::string,std::less<>> pathFields={"kind","rateRatio","radiusX","radiusY","angle","translationX","translationY","meander","feedback","spatialLimit"};if(!fieldsAreExact(*p,pathFields,{},"path",error))return std::nullopt;auto& path=scene.path;if(!requiredString(*p,"kind",path.kind,"path",error)||!requiredNumber(*p,"rateRatio",path.rateRatio,"path",error)||!requiredNumber(*p,"radiusX",path.radiusX,"path",error)||!requiredNumber(*p,"radiusY",path.radiusY,"path",error)||!requiredNumber(*p,"angle",path.angle,"path",error)||!requiredNumber(*p,"translationX",path.translationX,"path",error)||!requiredNumber(*p,"translationY",path.translationY,"path",error)||!requiredNumber(*p,"meander",path.meander,"path",error)||!requiredNumber(*p,"feedback",path.feedback,"path",error)||!requiredNumber(*p,"spatialLimit",path.spatialLimit,"path",error))return std::nullopt;
  const JsonArray* roles=array(*field(*top,"roles"));if(!roles){error={"roles","must be an array"};return std::nullopt;}const std::set<std::string,std::less<>> roleFields={"id","enabled","range","density","pattern","rhythm","variation","seedOffset","voiceRoute","midiRoute"};for(const auto& roleValue:*roles){const JsonObject* r=object(roleValue);if(!r){error={"roles","entries must be objects"};return std::nullopt;}if(!fieldsAreExact(*r,roleFields,{},"roles",error))return std::nullopt;RoleLane lane;std::string id;if(!requiredString(*r,"id",id,"roles",error)||!requiredNumber(*r,"range",lane.range,"roles",error)||!requiredNumber(*r,"density",lane.density,"roles",error)||!requiredNumber(*r,"variation",lane.variation,"roles",error)||!requiredString(*r,"voiceRoute",lane.voiceRoute,"roles",error)||!requiredString(*r,"midiRoute",lane.midiRoute,"roles",error)||!parseSeed(*field(*r,"seedOffset"),lane.seedOffset,error))return std::nullopt;if(id=="drone")lane.id=RoleId::drone;else if(id=="pad")lane.id=RoleId::pad;else if(id=="motifA")lane.id=RoleId::motifA;else if(id=="motifB")lane.id=RoleId::motifB;else{error={"roles.id","unknown role ID"};return std::nullopt;}const bool* enabled=boolean(*field(*r,"enabled"));if(!enabled){error={"roles.enabled","must be boolean"};return std::nullopt;}lane.enabled=*enabled;const JsonArray* pattern=array(*field(*r,"pattern"));const JsonArray* rhythm=array(*field(*r,"rhythm"));if(!pattern||!rhythm){error={"roles","pattern and rhythm must be arrays"};return std::nullopt;}for(const auto& item:*pattern){int degree{};if(!parseInteger(item,degree,"roles.pattern",error))return std::nullopt;lane.pattern.push_back(degree);}for(const auto& item:*rhythm){const auto* step=string(item);if(!step){error={"roles.rhythm","steps must be strings"};return std::nullopt;}if(*step=="note")lane.rhythm.push_back({RhythmStepKind::note});else if(*step=="rest")lane.rhythm.push_back({RhythmStepKind::rest});else if(*step=="tie")lane.rhythm.push_back({RhythmStepKind::tie});else{error={"roles.rhythm","unknown step"};return std::nullopt;}}scene.roles.push_back(std::move(lane));}
  const ValidationIssues issues=validateScene(scene);if(!issues.empty()){error={issues.front().field,issues.front().message};return std::nullopt;}return scene;
}

}  // namespace latticewake
