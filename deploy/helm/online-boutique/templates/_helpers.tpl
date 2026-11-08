{{/*
Image for Google microservices-demo components under image.registry.
Uses image.digests.<service> when set (sha256:...); otherwise image.tag.
*/}}
{{- define "online-boutique.googleSampleImage" -}}
{{- $root := .root -}}
{{- $svc := .service -}}
{{- $reg := $root.Values.image.registry -}}
{{- $tag := $root.Values.image.tag -}}
{{- $digests := default dict $root.Values.image.digests -}}
{{- $d := index $digests $svc -}}
{{- if and $d (ne (toString $d) "") -}}
{{- printf "%s/%s@%s" $reg $svc $d -}}
{{- else -}}
{{- printf "%s/%s:%s" $reg $svc $tag -}}
{{- end -}}
{{- end -}}
